#!/usr/bin/env bash

notify-send "SwirlDesk" "UI wird neu gestartet…"

pkill waybar 2>/dev/null
pkill dunst 2>/dev/null
pkill swaybg 2>/dev/null

sleep 0.3

dunst &
waybar &
~/.config/hypr/scripts/wallpaper-restore.sh &

notify-send "SwirlDesk" "UI neu gestartet"
