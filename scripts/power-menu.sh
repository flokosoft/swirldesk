#!/usr/bin/env bash

choice=$(printf "  Ausschalten\n  Neustarten\n󰌾  Sperren\n  Abmelden" | fuzzel --dmenu --prompt "Power: ")

case "$choice" in
    *Ausschalten)
        systemctl poweroff
        ;;
    *Neustarten)
        systemctl reboot
        ;;
    *Sperren)
        if command -v hyprlock >/dev/null 2>&1; then
            hyprlock
        else
            notify-send "Hyprlock ist nicht installiert"
        fi
        ;;
    *Abmelden)
        hyprctl dispatch exit
        ;;
esac
