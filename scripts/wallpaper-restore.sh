#!/usr/bin/env bash

CACHE_FILE="$HOME/.config/swirldesk/state/current_wallpaper"
WALLPAPER_DIR="$HOME/Bilder/Wallpapers"

if ! command -v swaybg >/dev/null 2>&1; then
    exit 1
fi

if [ -f "$CACHE_FILE" ]; then
    WALLPAPER=$(cat "$CACHE_FILE")
else
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f \
        \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) \
        | shuf -n 1)
fi

if [ -n "$WALLPAPER" ] && [ -f "$WALLPAPER" ]; then
    pkill swaybg 2>/dev/null
    swaybg -i "$WALLPAPER" -m fill &
fi
