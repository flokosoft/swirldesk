#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/Bilder/Wallpapers"
# CACHE_DIR="$HOME/.cache/hypr/wallpaper-thumbs"
CACHE_DIR="$HOME/.cache/swirldesk/wallpaper-thumbs"
CURRENT_FILE="$HOME/.config/swirldesk/state/current_wallpaper"

mkdir -p "$CACHE_DIR"
mkdir -p "$(dirname "$CURRENT_FILE")"

if ! command -v swaybg >/dev/null 2>&1; then
    notify-send "Wallpaper" "swaybg ist nicht installiert"
    exit 1
fi

if ! command -v yad >/dev/null 2>&1; then
    notify-send "Wallpaper" "yad ist nicht installiert, nutze Fuzzel-Fallback"

    choice=$(find "$WALLPAPER_DIR" -type f \
        \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) \
        | sort \
        | sed "s|$WALLPAPER_DIR/||" \
        | fuzzel --dmenu --prompt "Wallpaper: ")

    [ -z "$choice" ] && exit 0

    selected="$WALLPAPER_DIR/$choice"

    pkill swaybg 2>/dev/null
    swaybg -i "$selected" -m fill &
    echo "$selected" > "$CURRENT_FILE"
    notify-send "Wallpaper gesetzt" "$(basename "$selected")"
    exit 0
fi

mapfile -t wallpapers < <(
    find "$WALLPAPER_DIR" -type f \
        \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) \
        | sort
)

if [ "${#wallpapers[@]}" -eq 0 ]; then
    notify-send "Wallpaper" "Keine Bilder in $WALLPAPER_DIR gefunden"
    exit 1
fi

list_data=""

for wallpaper in "${wallpapers[@]}"; do
    filename="$(basename "$wallpaper")"
    thumb="$CACHE_DIR/${filename%.*}.png"

    if [ ! -f "$thumb" ] || [ "$wallpaper" -nt "$thumb" ]; then
        magick "$wallpaper" -thumbnail 240x135^ -gravity center -extent 240x135 "$thumb" 2>/dev/null
    fi

    list_data+="$thumb
$filename
$wallpaper
"
done

selected="$(
    printf "%s" "$list_data" | yad \
        --title="Wallpaper auswählen" \
        --window-icon=preferences-desktop-wallpaper \
        --width=900 \
        --height=600 \
        --center \
        --list \
        --print-column=3 \
        --separator="" \
        --column="Vorschau:IMG" \
        --column="Name" \
        --column="Pfad:HD" \
        --button="Setzen:0" \
        --button="Abbrechen:1"
)"

[ -z "$selected" ] && exit 0
[ ! -f "$selected" ] && exit 1

pkill swaybg 2>/dev/null
swaybg -i "$selected" -m fill &

echo "$selected" > "$CURRENT_FILE"

notify-send "Wallpaper gesetzt" "$(basename "$selected")"
