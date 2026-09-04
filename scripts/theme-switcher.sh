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

# Validate the Hyprland-facing core before changing the active theme. A partial
# extraction must never leave Hyprland sourcing files that are not present.
for req in hypr/colors.conf hypr/appearance.conf hypr/cursor.conf; do
    if [ ! -f "$selected/$req" ]; then
        notify-send "SwirlDesk Theme" "Theme incomplete: $choice/$req"
        exit 1
    fi
done

# Atomic-ish replacement of the current_theme symlink (GNU mv -T on Debian).
tmp_link="$STATE_DIR/.current_theme.$$"
rm -f "$tmp_link"
ln -s "$selected" "$tmp_link"
mv -Tf "$tmp_link" "$CURRENT_THEME_LINK"
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

# Hyprlock
# FIELD ships a theme-specific lockscreen. Other themes fall back to the
# original SwirlDesk lockscreen, so switching themes remains reversible.
mkdir -p "$HOME/.config/hypr"
if [ -f "$selected/hyprlock/hyprlock.conf" ]; then
    ln -sfn "$selected/hyprlock/hyprlock.conf" "$HOME/.config/hypr/hyprlock.conf"
else
    ln -sfn "$HOME/.config/swirldesk/hypr/hyprlock.conf" "$HOME/.config/hypr/hyprlock.conf"
fi

# Kitty
if [ -f "$selected/kitty/kitty.conf" ]; then
    mkdir -p "$HOME/.config/kitty"
    ln -sf "$selected/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
fi

# Theme-specific icon overlay. FIELD only overrides a small set of place/device
# icons and inherits all other icons from Papirus/Adwaita.
if [ -d "$selected/icons/SwirlDesk-FIELD" ]; then
    mkdir -p "$HOME/.local/share/icons"
    ln -sfn "$selected/icons/SwirlDesk-FIELD" "$HOME/.local/share/icons/SwirlDesk-FIELD"
fi

# GTK
if [ -f "$selected/gtk/settings.ini" ]; then
    mkdir -p "$HOME/.config/gtk-3.0"
    mkdir -p "$HOME/.config/gtk-4.0"
    ln -sf "$selected/gtk/settings.ini" "$HOME/.config/gtk-3.0/settings.ini"
    ln -sf "$selected/gtk/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"
fi
if [ -f "$selected/gtk/gtk-3.css" ]; then
    ln -sf "$selected/gtk/gtk-3.css" "$HOME/.config/gtk-3.0/gtk.css"
elif [ -L "$HOME/.config/gtk-3.0/gtk.css" ] && readlink -f "$HOME/.config/gtk-3.0/gtk.css" | grep -q '/swirldesk/themes/'; then
    rm -f "$HOME/.config/gtk-3.0/gtk.css"
fi
if [ -f "$selected/gtk/gtk-4.css" ]; then
    ln -sf "$selected/gtk/gtk-4.css" "$HOME/.config/gtk-4.0/gtk.css"
elif [ -L "$HOME/.config/gtk-4.0/gtk.css" ] && readlink -f "$HOME/.config/gtk-4.0/gtk.css" | grep -q '/swirldesk/themes/'; then
    rm -f "$HOME/.config/gtk-4.0/gtk.css"
fi

# Starship prompt (theme-specific). When leaving a theme that owns the symlink,
# remove it so Starship falls back to its normal/default configuration.
if [ -f "$selected/starship/starship.toml" ]; then
    mkdir -p "$HOME/.config"
    ln -sfn "$selected/starship/starship.toml" "$HOME/.config/starship.toml"
elif [ -L "$HOME/.config/starship.toml" ] && readlink -f "$HOME/.config/starship.toml" | grep -q '/swirldesk/themes/'; then
    rm -f "$HOME/.config/starship.toml"
fi

# Theme wallpaper (optional)
# A theme may set THEME_WALLPAPER relative to ~/.config/swirldesk in theme.conf.
if [ -f "$selected/theme.conf" ]; then
    unset THEME_WALLPAPER THEME_WALLPAPER_MODE
    # shellcheck disable=SC1090
    . "$selected/theme.conf"

    if [ -n "${THEME_WALLPAPER:-}" ]; then
        wallpaper="$HOME/.config/swirldesk/$THEME_WALLPAPER"
        wallpaper_mode="${THEME_WALLPAPER_MODE:-fill}"

        if [ -f "$wallpaper" ] && command -v swaybg >/dev/null 2>&1; then
            pkill swaybg 2>/dev/null || true
            swaybg -i "$wallpaper" -m "$wallpaper_mode" &
            echo "$wallpaper" > "$STATE_DIR/current_wallpaper"
        fi
    fi
fi

# FIELD visual profile persistence. Theme switching normally applies the
# theme.conf wallpaper first; FIELD then restores the user's selected visual
# profile (clean / AOR1 ghost / MultiCam ghost) without adding another keybind.
if [ "$choice" = "swirldesk-field" ] && [ -x "$HOME/.config/swirldesk/scripts/field-wallpaper-profile.sh" ]; then
    profile="$(cat "$STATE_DIR/field_wallpaper_profile" 2>/dev/null || echo clean)"
    "$HOME/.config/swirldesk/scripts/field-wallpaper-profile.sh" --quiet --apply "$profile" 2>/dev/null || true
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

pkill waybar 2>/dev/null || true
pkill -x dunst 2>/dev/null || true
"$HOME/.config/swirldesk/scripts/dunst-start.sh" >/dev/null 2>&1 || true
waybar &

# dunst-start.sh already verifies ownership of org.freedesktop.Notifications.
# Avoid dunstctl here because its private control interface can race with D-Bus
# activation on some Debian/Wayland sessions.
if command -v gdbus >/dev/null 2>&1; then
    ntf_owner=$(gdbus call --session --dest org.freedesktop.DBus --object-path /org/freedesktop/DBus --method org.freedesktop.DBus.NameHasOwner org.freedesktop.Notifications 2>/dev/null || true)
    [[ "$ntf_owner" == *true* ]] && notify-send "FIELD // THEME" "$choice active"
fi
