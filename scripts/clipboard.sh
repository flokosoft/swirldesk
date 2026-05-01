#!/usr/bin/env bash

if ! command -v cliphist >/dev/null 2>&1; then
    notify-send "Clipboard" "cliphist ist nicht installiert"
    exit 1
fi

selection=$(cliphist list | fuzzel --dmenu --prompt "Clipboard: ")

if [ -n "$selection" ]; then
    echo "$selection" | cliphist decode | wl-copy
    notify-send "Clipboard" "Eintrag kopiert"
fi
