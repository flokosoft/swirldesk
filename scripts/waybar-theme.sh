#!/usr/bin/env bash

THEME_DIR="$HOME/.config/swirldesk/themes/waybar"
WAYBAR_DIR="$HOME/.config/waybar"
CACHE_FILE="$HOME/.config/swirldesk/state/current_waybar_theme"

if ! command -v fuzzel >/dev/null 2>&1; then
    notify-send "Waybar Theme" "fuzzel ist nicht installiert"
    exit 1
fi

mapfile -t themes < <(
    find "$THEME_DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort
)

if [ "${#themes[@]}" -eq 0 ]; then
    notify-send "Waybar Theme" "Keine Themes gefunden"
    exit 1
fi

choice=$(printf '%s\n' "${themes[@]}" | fuzzel --dmenu --prompt "Waybar Theme: ")

[ -z "$choice" ] && exit 0

selected="$THEME_DIR/$choice"

if [ ! -f "$selected/config" ] || [ ! -f "$selected/style.css" ]; then
    notify-send "Waybar Theme" "Theme ist unvollständig: $choice"
    exit 1
fi

ln -sf "$selected/config" "$WAYBAR_DIR/config"
ln -sf "$selected/style.css" "$WAYBAR_DIR/style.css"

mkdir -p "$HOME/.config/swirldesk/state"
echo "$choice" > "$CACHE_FILE"

pkill waybar 2>/dev/null
waybar &

notify-send "Waybar Theme gesetzt" "$choice"
