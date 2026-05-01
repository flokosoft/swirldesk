#!/usr/bin/env bash

# choice=$(printf "  SwirlDesk Info\n  Systeminfo\n󰓅  Systemmonitor\n󰕾  Audio\n  Netzwerk\n󰂯  Bluetooth\n󰍹  Monitor-Setup\n󰔎  SwirlDesk Theme\n  Wallpaper\n󰔎  Waybar Theme\n󰌌  Tastenkürzel\n󰨇  Screenshot\n  Clipboard\n󰄛  UI neu starten\n  Power-Menü" | \
#     fuzzel --dmenu \
#     --prompt "SwirlDesk: " \
#     --width 44 \
#     --lines 15 \
#     --font "JetBrainsMono Nerd Font:size=11")
choice=$(printf "  SwirlDesk Info\n󰙅  Anzeigename ändern\n  Systeminfo\n󰓅  Systemmonitor\n󰕾  Audio\n  Netzwerk\n󰂯  Bluetooth\n󰍹  Monitor-Setup\n  Wallpaper\n󰔎  SwirlDesk Theme\n󰌌  Tastenkürzel\n󰨇  Screenshot\n  Clipboard\n󰄛  UI neu starten\n  Power-Menü" | \
    fuzzel --dmenu \
    --prompt "SwirlDesk: " \
    --width 44 \
    --lines 16 \
    --font "JetBrainsMono Nerd Font:size=11")


case "$choice" in
    *"SwirlDesk Info"*)
        "$HOME/.config/swirldesk/scripts/about.sh"
        ;;

    *"Anzeigename ändern"*)
        "$HOME/.config/swirldesk/scripts/set-display-name.sh"
        ;;

    *Systeminfo*)
        "$HOME/.config/swirldesk/scripts/system-info.sh"
        ;;

    *Systemmonitor*)
        kitty --class btop-floating -e btop
        ;;

    *Audio*)
        pavucontrol
        ;;

    *Netzwerk*)
        nm-connection-editor
        ;;

    *Bluetooth*)
        if command -v blueman-manager >/dev/null 2>&1; then
            blueman-manager
        else
            notify-send "Bluetooth" "blueman-manager ist nicht installiert"
        fi
        ;;

    *Monitor-Setup*)
        if command -v swirl-monitors >/dev/null 2>&1; then
            swirl-monitors
        else
            nwg-displays -m "$HOME/.config/hypr/monitors-nwg.conf"
        fi
        ;;

    *"SwirlDesk Theme"*)
        "$HOME/.config/swirldesk/scripts/theme-switcher.sh"
        ;;

    *Wallpaper*)
        "$HOME/.config/swirldesk/scripts/wallpaper-select.sh"
        ;;

    *"Waybar Theme"*)
        "$HOME/.config/swirldesk/scripts/waybar-theme.sh"
        ;;

    *Tastenkürzel*)
        "$HOME/.config/swirldesk/scripts/keybinds-help.sh"
        ;;

    *Screenshot*)
        "$HOME/.config/swirldesk/scripts/screenshot.sh"
        ;;

    *Clipboard*)
        "$HOME/.config/swirldesk/scripts/clipboard.sh"
        ;;

    *"UI neu starten"*)
        swirl-restart-ui
        ;;

    *Power*)
        "$HOME/.config/swirldesk/scripts/power-menu.sh"
        ;;
esac
