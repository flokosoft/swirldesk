#!/usr/bin/env bash

THEMES_DIR="$HOME/.config/swirldesk/themes"
STATE_DIR="$HOME/.config/swirldesk/state"
CURRENT_THEME_LINK="$STATE_DIR/current_theme"

mkdir -p "$STATE_DIR"

mapfile -t themes < <(
    find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort
)

if [ "${#themes[@]}" -eq 0 ]; then
    notify-send "SwirlDesk Theme" "Keine Themes gefunden"
    exit 1
fi

choice=$(printf "%s\n" "${themes[@]}" | fuzzel \
    --dmenu \
    --prompt "SwirlDesk Theme: " \
    --width 42 \
    --lines 12 \
    --font "JetBrainsMono Nerd Font:size=11")

[ -z "$choice" ] && exit 0

selected="$THEMES_DIR/$choice"

if [ ! -d "$selected" ]; then
    notify-send "SwirlDesk Theme" "Theme nicht gefunden: $choice"
    exit 1
fi

ln -sfn "$selected" "$CURRENT_THEME_LINK"
echo "$choice" > "$STATE_DIR/current_theme_name"

# Waybar
if [ -f "$selected/waybar/config" ] && [ -f "$selected/waybar/style.css" ]; then
    ln -sf "$selected/waybar/config" "$HOME/.config/waybar/config"
    ln -sf "$selected/waybar/style.css" "$HOME/.config/waybar/style.css"
fi

# Fuzzel
if [ -f "$selected/fuzzel/fuzzel.ini" ]; then
    mkdir -p "$HOME/.config/fuzzel"
    ln -sf "$selected/fuzzel/fuzzel.ini" "$HOME/.config/fuzzel/fuzzel.ini"
fi

# Dunst
if [ -f "$selected/dunst/dunstrc" ]; then
    mkdir -p "$HOME/.config/dunst"
    ln -sf "$selected/dunst/dunstrc" "$HOME/.config/dunst/dunstrc"
fi

# Kitty
if [ -f "$selected/kitty/kitty.conf" ]; then
    mkdir -p "$HOME/.config/kitty"
    ln -sf "$selected/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
fi

# GTK
if [ -f "$selected/gtk/settings.ini" ]; then
    mkdir -p "$HOME/.config/gtk-3.0"
    mkdir -p "$HOME/.config/gtk-4.0"
    ln -sf "$selected/gtk/settings.ini" "$HOME/.config/gtk-3.0/settings.ini"
    ln -sf "$selected/gtk/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"
fi

# Cursor
if [ -f "$selected/hypr/cursor.conf" ]; then
    if grep -q "XCURSOR_THEME" "$selected/hypr/cursor.conf"; then
        CURSOR_THEME="$(grep "XCURSOR_THEME" "$selected/hypr/cursor.conf" | head -n1 | cut -d',' -f2)"
        CURSOR_SIZE="$(grep "XCURSOR_SIZE" "$selected/hypr/cursor.conf" | head -n1 | cut -d',' -f2)"

        CURSOR_SIZE="${CURSOR_SIZE:-24}"

        mkdir -p "$HOME/.icons/default"
        cat > "$HOME/.icons/default/index.theme" <<EOF
[Icon Theme]
Inherits=$CURSOR_THEME
EOF

        mkdir -p "$HOME/.local/share/icons/default"
        ln -sf "$HOME/.icons/default/index.theme" "$HOME/.local/share/icons/default/index.theme"

        gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE" 2>/dev/null || true
    fi
fi

hyprctl reload 2>/dev/null

pkill waybar 2>/dev/null
waybar &

pkill dunst 2>/dev/null
dunst &

notify-send "SwirlDesk Theme gesetzt" "$choice"
