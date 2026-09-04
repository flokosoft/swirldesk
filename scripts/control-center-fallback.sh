#!/usr/bin/env bash
set -u

choice=$(printf '%s\n' \
    '01 // STATUS      local node' \
    '02 // RUN         applications' \
    '03 // SYS         system monitor' \
    '04 // COMMS       network' \
    '05 // COMMS       WireGuard toggle' \
    '06 // I/O         audio' \
    '07 // I/O         bluetooth' \
    '08 // DISPLAY     monitor setup' \
    '09 // VISUAL      FIELD profile' \
    '10 // DESKTOP     wallpaper' \
    '11 // DESKTOP     theme' \
    '12 // TOOLS       clipboard' \
    '13 // TOOLS       screenshot' \
    '14 // TOOLS       keybinds' \
    '15 // SESSION     lock' \
    '16 // SESSION     power' \
    '17 // SYSTEM      restart UI' | \
    fuzzel --dmenu --prompt 'FIELD CONTROL // ' --width 48 --lines 17 --font 'JetBrainsMono Nerd Font:size=11')

case "$choice" in
    '01 // STATUS      local node') "$HOME/.config/swirldesk/scripts/field-status-toggle.sh" ;;
    '02 // RUN         applications') fuzzel ;;
    '03 // SYS         system monitor') kitty --class btop-floating -e btop ;;
    '04 // COMMS       network') nm-connection-editor ;;
    '05 // COMMS       WireGuard toggle') "$HOME/.config/swirldesk/scripts/wireguard-toggle.sh" ;;
    '06 // I/O         audio') pavucontrol ;;
    '07 // I/O         bluetooth')
        if command -v blueman-manager >/dev/null 2>&1; then blueman-manager; else notify-send 'FIELD // BT' 'blueman-manager not installed'; fi ;;
    '08 // DISPLAY     monitor setup')
        if command -v swirl-monitors >/dev/null 2>&1; then swirl-monitors; else nwg-displays -m "$HOME/.config/hypr/monitors-nwg.conf"; fi ;;
    '09 // VISUAL      FIELD profile') "$HOME/.config/swirldesk/scripts/field-wallpaper-profile.sh" ;;
    '10 // DESKTOP     wallpaper') "$HOME/.config/swirldesk/scripts/wallpaper-select.sh" ;;
    '11 // DESKTOP     theme') "$HOME/.config/swirldesk/scripts/theme-switcher.sh" ;;
    '12 // TOOLS       clipboard') "$HOME/.config/swirldesk/scripts/clipboard.sh" ;;
    '13 // TOOLS       screenshot') "$HOME/.config/swirldesk/scripts/screenshot.sh" ;;
    '14 // TOOLS       keybinds') "$HOME/.config/swirldesk/scripts/keybinds-help.sh" ;;
    '15 // SESSION     lock') hyprlock ;;
    '16 // SESSION     power') "$HOME/.config/swirldesk/scripts/power-menu.sh" ;;
    '17 // SYSTEM      restart UI') "$HOME/.config/swirldesk/scripts/restart-ui.sh" ;;
esac
