#!/usr/bin/env bash
set -euo pipefail

SWIRL_DIR="$HOME/.config/swirldesk"
CURRENT_THEME_LINK="$SWIRL_DIR/state/current_theme"

echo "==> Setze SwirlDesk-Symlinks..."

mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.config/waybar"
mkdir -p "$HOME/.config/fuzzel"
mkdir -p "$HOME/.config/dunst"
mkdir -p "$HOME/.config/kitty"
mkdir -p "$HOME/.config/hypr/conf"
mkdir -p "$HOME/.config/gtk-3.0"
mkdir -p "$HOME/.config/gtk-4.0"
mkdir -p "$SWIRL_DIR/state"

backup_if_needed() {
    local target="$1"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        local backup="${target}.bak.$(date +%Y%m%d-%H%M%S)"
        echo "----> Sichere bestehende Datei: $target -> $backup"
        mv "$target" "$backup"
    fi
}

safe_link() {
    local source="$1"
    local target="$2"

    if [ ! -e "$source" ]; then
        echo "WARNUNG: Quelle fehlt, überspringe: $source"
        return 0
    fi

    backup_if_needed "$target"
    ln -sfn "$source" "$target"
}

# Bin-Wrapper
if [ -d "$SWIRL_DIR/bin" ]; then
    for file in "$SWIRL_DIR"/bin/*; do
        [ -f "$file" ] || continue
        chmod +x "$file"
        safe_link "$file" "$HOME/.local/bin/$(basename "$file")"
    done
fi

# Aktuelles Theme setzen, falls noch keins gesetzt ist
if [ ! -L "$CURRENT_THEME_LINK" ]; then
    if [ -d "$SWIRL_DIR/themes/swirldesk-debian" ]; then
        ln -sfn "$SWIRL_DIR/themes/swirldesk-debian" "$CURRENT_THEME_LINK"
        echo "swirldesk-debian" > "$SWIRL_DIR/state/current_theme_name"
    elif [ -d "$SWIRL_DIR/themes/swirldesk-graphite" ]; then
        ln -sfn "$SWIRL_DIR/themes/swirldesk-graphite" "$CURRENT_THEME_LINK"
        echo "swirldesk-graphite" > "$SWIRL_DIR/state/current_theme_name"
    else
        echo "FEHLER: Kein Standard-Theme gefunden."
        exit 1
    fi
fi

if [ ! -L "$CURRENT_THEME_LINK" ] || [ ! -d "$CURRENT_THEME_LINK" ]; then
    echo "FEHLER: Aktives Theme ist ungültig: $CURRENT_THEME_LINK"
    exit 1
fi

CURRENT_THEME="$CURRENT_THEME_LINK"

# Waybar
safe_link "$CURRENT_THEME/waybar/config" "$HOME/.config/waybar/config"
safe_link "$CURRENT_THEME/waybar/style.css" "$HOME/.config/waybar/style.css"

# Fuzzel
safe_link "$CURRENT_THEME/fuzzel/fuzzel.ini" "$HOME/.config/fuzzel/fuzzel.ini"

# Dunst
safe_link "$CURRENT_THEME/dunst/dunstrc" "$HOME/.config/dunst/dunstrc"

# Kitty
safe_link "$CURRENT_THEME/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"

# Fastfetch
mkdir -p "$HOME/.config/fastfetch"
safe_link "$SWIRL_DIR/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"

# GTK
safe_link "$CURRENT_THEME/gtk/settings.ini" "$HOME/.config/gtk-3.0/settings.ini"
safe_link "$CURRENT_THEME/gtk/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"

# Hyprland
safe_link "$SWIRL_DIR/hypr/hyprland.conf" "$HOME/.config/hypr/hyprland.conf"
safe_link "$SWIRL_DIR/hypr/hyprlock.conf" "$HOME/.config/hypr/hyprlock.conf"

if [ -f "$SWIRL_DIR/hypr/hypridle.conf" ]; then
    safe_link "$SWIRL_DIR/hypr/hypridle.conf" "$HOME/.config/hypr/hypridle.conf"
fi

safe_link "$SWIRL_DIR/hypr/conf/environment.conf" "$HOME/.config/hypr/conf/environment.conf"
safe_link "$SWIRL_DIR/hypr/conf/monitors.conf" "$HOME/.config/hypr/conf/monitors.conf"
safe_link "$SWIRL_DIR/hypr/conf/input.conf" "$HOME/.config/hypr/conf/input.conf"
safe_link "$SWIRL_DIR/hypr/conf/autostart.conf" "$HOME/.config/hypr/conf/autostart.conf"
safe_link "$SWIRL_DIR/hypr/conf/keybinds.conf" "$HOME/.config/hypr/conf/keybinds.conf"
safe_link "$SWIRL_DIR/hypr/conf/windowrules.conf" "$HOME/.config/hypr/conf/windowrules.conf"

# monitor file bleibt lokal
touch "$HOME/.config/hypr/monitors-nwg.conf"

echo "==> Symlinks gesetzt."
