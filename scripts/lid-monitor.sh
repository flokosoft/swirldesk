#!/usr/bin/env bash

set -u

INTERNAL_MONITOR="eDP-1"

external_monitor_count() {
    hyprctl -j monitors |
        jq --arg internal "$INTERNAL_MONITOR" \
           '[.[] | select(.name != $internal)] | length'
}

lid_is_closed() {
    grep -qi "closed" /proc/acpi/button/lid/*/state 2>/dev/null
}

disable_internal_monitor() {
    hyprctl keyword monitor "$INTERNAL_MONITOR,disable" >/dev/null
}

restore_saved_layout() {
    # Lädt auch die von nwg-displays erzeugten Monitorregeln neu.
    hyprctl reload >/dev/null
}

case "${1:-sync}" in
    close)
        # Dock/KVM kurz Zeit geben, die Monitore bereitzustellen.
        sleep 1

        if (( $(external_monitor_count) > 0 )); then
            disable_internal_monitor
            notify-send "SwirlDesk" "Laptopdisplay deaktiviert"
        else
            # Ohne externen Bildschirm normales Laptop-Verhalten.
            loginctl lock-session
            sleep 1
            systemctl suspend
        fi
        ;;

    open)
        restore_saved_layout
        notify-send "SwirlDesk" "Laptopdisplay aktiviert"
        ;;

    sync)
        # Wird bei Monitor-Hotplug aufgerufen.
        sleep 1

        if lid_is_closed && (( $(external_monitor_count) > 0 )); then
            disable_internal_monitor
        fi
        ;;

    *)
        echo "Verwendung: $0 {close|open|sync}" >&2
        exit 1
        ;;
esac
