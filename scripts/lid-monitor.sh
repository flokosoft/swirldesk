#!/usr/bin/env bash

set -euo pipefail

INTERNAL_MONITOR="eDP-1"

PROFILE_DIR="$HOME/.config/swirldesk/hypr/monitors"
STATE_DIR="$HOME/.local/state/swirldesk"
ACTIVE_PROFILE="$STATE_DIR/monitors-active.conf"

external_monitor_count() {
    hyprctl -j monitors |
        jq --arg internal "$INTERNAL_MONITOR" \
            '[.[] | select(.name != $internal)] | length'
}

lid_is_closed() {
    grep -qi "closed" /proc/acpi/button/lid/*/state 2>/dev/null
}

activate_profile() {
    local profile="$1"

    mkdir -p "$STATE_DIR"

    ln -sfn \
        "$PROFILE_DIR/${profile}.conf" \
        "$ACTIVE_PROFILE"

    hyprctl reload
}

activate_open_profile() {
    activate_profile "open"
}

activate_docked_profile() {
    local external_count

    external_count="$(external_monitor_count)"

    # Internes Display niemals abschalten,
    # wenn kein externer Monitor vorhanden ist.
    if (( external_count == 0 )); then
        return 1
    fi

    activate_profile "docked"
}

case "${1:-sync}" in
    close)
        sleep 1

        if activate_docked_profile; then
            notify-send \
                "SwirlDesk" \
                "Dock-Modus: Laptopdisplay deaktiviert"
        else
            loginctl lock-session
            systemctl suspend
        fi
        ;;

    open)
        activate_open_profile

        notify-send \
            "SwirlDesk" \
            "Laptopdisplay aktiviert"
        ;;

    sync)
        sleep 1

        if lid_is_closed; then
            activate_docked_profile || true
        else
            activate_open_profile
        fi
        ;;

    *)
        echo "Verwendung: $0 {open|close|sync}" >&2
        exit 1
        ;;
esac
