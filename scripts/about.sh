#!/usr/bin/env bash

HOSTNAME="$(hostname)"
KERNEL="$(uname -r)"
UPTIME="$(uptime -p | sed 's/up //')"
SESSION="${XDG_CURRENT_DESKTOP:-unknown}"
WAYBAR_THEME="unbekannt"

if [ -f "$HOME/.config/swirldesk/state/current_waybar_theme" ]; then
    WAYBAR_THEME="$(cat "$HOME/.config/swirldesk/state/current_waybar_theme")"
fi

CURRENT_WALLPAPER="unbekannt"

if [ -f "$HOME/.config/swirldesk/state/current_wallpaper" ]; then
    CURRENT_WALLPAPER="$(basename "$(cat "$HOME/.config/swirldesk/state/current_wallpaper")")"
fi

INFO="  SwirlDesk

Rechner:      $HOSTNAME
Session:      $SESSION
Kernel:       $KERNEL
Laufzeit:     $UPTIME

Waybar Theme: $WAYBAR_THEME
Wallpaper:    $CURRENT_WALLPAPER"

printf "%s" "$INFO" | fuzzel \
    --dmenu \
    --prompt "SwirlDesk Info: " \
    --width 60 \
    --lines 10 \
    --font "JetBrainsMono Nerd Font:size=10"
