#!/usr/bin/env bash
set -u

# SwirlDesk FIELD // Power control
# Numbering and wording mirror FIELD CONTROL and FIELD STATUS.
menu() {
    fuzzel --dmenu --prompt "$1" --width 41 --lines "$2" --font "JetBrainsMono Nerd Font:size=11"
}

choice=$(printf '%s\n' \
    '01 // LOCK       secure session' \
    '02 // SUSPEND    sleep' \
    '03 // LOGOUT     end Hyprland session' \
    '04 // REBOOT     restart system' \
    '05 // SHUTDOWN   power off' | menu 'PWR CONTROL // ' 5)

[ -n "${choice:-}" ] || exit 0

action=$(printf '%s' "$choice" | awk '{print $3}')

confirm() {
    local what="$1" answer
    answer=$(printf '%s\n' \
        "01 // CONFIRM    $what" \
        '02 // CANCEL' | menu 'PWR CHECK // ' 2)
    [[ "$answer" == "01 // CONFIRM    $what" ]]
}

case "$action" in
    LOCK)
        if command -v hyprlock >/dev/null 2>&1; then
            hyprlock
        else
            notify-send -u critical 'PWR // ERROR' 'hyprlock not installed'
        fi
        ;;
    SUSPEND)
        systemctl suspend
        ;;
    LOGOUT)
        if confirm LOGOUT; then hyprctl dispatch exit; fi
        ;;
    REBOOT)
        if confirm REBOOT; then systemctl reboot; fi
        ;;
    SHUTDOWN)
        if confirm SHUTDOWN; then systemctl poweroff; fi
        ;;
esac
