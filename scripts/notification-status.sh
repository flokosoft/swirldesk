#!/usr/bin/env bash
set -u

# SwirlDesk FIELD // notification status
# Prefer dunstctl when its control interface is available. Debian/Wayland setups
# can occasionally have a working Dunst notification server while dunstctl's
# private control interface is unavailable; in that case use a small runtime
# state file instead of showing a permanent "NTF ?".

RUNTIME_BASE="${XDG_RUNTIME_DIR:-/tmp}"
STATE_FILE="$RUNTIME_BASE/swirldesk-field-ntf-${UID}.state"

json() {
    printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$1" "$2" "$3"
}

has_notification_owner() {
    if command -v gdbus >/dev/null 2>&1; then
        local out
        out="$(gdbus call --session \
            --dest org.freedesktop.DBus \
            --object-path /org/freedesktop/DBus \
            --method org.freedesktop.DBus.NameHasOwner \
            org.freedesktop.Notifications 2>/dev/null || true)"
        [[ "$out" == *true* ]]
        return
    fi

    if command -v dbus-send >/dev/null 2>&1; then
        dbus-send --session --print-reply \
            --dest=org.freedesktop.DBus \
            /org/freedesktop/DBus \
            org.freedesktop.DBus.NameHasOwner \
            string:org.freedesktop.Notifications 2>/dev/null | grep -q 'boolean true'
        return
    fi

    return 1
}

if ! has_notification_owner; then
    rm -f "$STATE_FILE" 2>/dev/null || true
    json "NTF OFF" "Notification service offline" "offline"
    exit 0
fi

# First choice: query Dunst directly. Keep this bounded because Waybar invokes
# this script often and must never block on a broken D-Bus control interface.
if command -v dunstctl >/dev/null 2>&1; then
    status="$(timeout 0.8s dunstctl is-paused 2>/dev/null || true)"
    case "$status" in
        true)
            printf 'paused\n' > "$STATE_FILE"
            json "NTF HOLD" "Benachrichtigungen pausiert" "paused"
            exit 0
            ;;
        false)
            printf 'running\n' > "$STATE_FILE"
            json "NTF ON" "FIELD Notifications aktiv" "active"
            exit 0
            ;;
    esac
fi

# Compatibility fallback: notifications are demonstrably online, but the
# private dunstctl interface is not. Track only pause/unpause actions performed
# through SwirlDesk. Default to ON for a fresh session.
state="running"
if [[ -r "$STATE_FILE" ]]; then
    read -r state < "$STATE_FILE" || state="running"
fi

if [[ "$state" == "paused" ]]; then
    json "NTF HOLD" "Notifications pausiert // FIELD compatibility control" "paused"
else
    json "NTF ON" "Notification service online // FIELD compatibility control" "active"
fi
