#!/usr/bin/env bash

choice=$(printf "󰍜  Apps\n󰅶  Terminal\n  Dateien\n  \n󰔎  Waybar Theme Wallpaper wechseln\n󰨇  Screenshot\n  Clipboard\n󰕾  Audio\n  Netzwerk\n  Power" | fuzzel --dmenu --prompt "Menü: ")

case "$choice" in
    *Apps)
        fuzzel
        ;;
    *Terminal)
        kitty
        ;;
    *Dateien)
        thunar
        ;;
    *"Waybar Theme"*)
        ~/.config/hypr/scripts/waybar-theme.sh
        ;;
    *Wallpaper*)
        ~/.config/hypr/scripts/wallpaper.sh
        ;;
    *Screenshot*)
        ~/.config/hypr/scripts/screenshot.sh
        ;;
    *Clipboard*)
        ~/.config/hypr/scripts/clipboard.sh
        ;;
    *Audio*)
        pavucontrol
        ;;
    *Netzwerk*)
        nm-connection-editor
        ;;
    *Power*)
        ~/.config/hypr/scripts/power-menu.sh
        ;;
esac
