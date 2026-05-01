#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/Bilder/Wallpapers"

if ! command -v swaybg >/dev/null 2>&1; then
    notify-send "Wallpaper" "swaybg ist nicht installiert"
    exit 1
fi

WALLPAPER=$(find "$WALLPAPER_DIR" -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) \
    | shuf -n 1)

if [ -z "$WALLPAPER" ]; then
    notify-send "Wallpaper" "Keine Bilder in $WALLPAPER_DIR gefunden"
    exit 1
fi

pkill swaybg 2>/dev/null

swaybg -i "$WALLPAPER" -m fill &

mkdir -p "$HOME/.config/swirldesk/state"
echo "$WALLPAPER" > "$HOME/.config/swirldesk/state/current_wallpaper"

notify-send "Wallpaper zufällig gesetzt" "$(basename "$WALLPAPER")"
