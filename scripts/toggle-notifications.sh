#!/usr/bin/env bash
set -u

RUNTIME_BASE="${XDG_RUNTIME_DIR:-/tmp}"
STATE_FILE="$RUNTIME_BASE/swirldesk-field-ntf-${UID}.state"

# Prefer the official control utility when its private interface actually works.
if command -v dunstctl >/dev/null 2>&1; then
    status="$(timeout 0.8s dunstctl is-paused 2>/dev/null || true)"
    case "$status" in
        true)
            if timeout 0.8s dunstctl set-paused false >/dev/null 2>&1; then
                printf 'running\n' > "$STATE_FILE"
                notify-send "FIELD // NTF" "Notifications online"
                exit 0
            fi
            ;;
        false)
            if timeout 0.8s dunstctl set-paused true >/dev/null 2>&1; then
                printf 'paused\n' > "$STATE_FILE"
                exit 0
            fi
            ;;
    esac
fi

# Compatibility path: resolve the process which owns the standard notification
# D-Bus name. This does not depend on the process being discoverable as "dunst"
# via pgrep. Signals are supported by Dunst as a fallback for pause/unpause.
if ! command -v gdbus >/dev/null 2>&1; then
    notify-send "FIELD // NTF" "Notification control unavailable"
    exit 1
fi

server="$(gdbus call --session \
    --dest org.freedesktop.Notifications \
    --object-path /org/freedesktop/Notifications \
    --method org.freedesktop.Notifications.GetServerInformation 2>/dev/null || true)"

if [[ "$server" != *Dunst* && "$server" != *dunst* ]]; then
    notify-send "FIELD // NTF" "Notification server is not Dunst"
    exit 1
fi

owner_raw="$(gdbus call --session \
    --dest org.freedesktop.DBus \
    --object-path /org/freedesktop/DBus \
    --method org.freedesktop.DBus.GetNameOwner \
    org.freedesktop.Notifications 2>/dev/null || true)"
owner="$(printf '%s' "$owner_raw" | sed -n "s/^('\\([^']*\\)',)$/\\1/p")"

if [[ -z "$owner" ]]; then
    notify-send "FIELD // NTF" "Could not resolve notification owner"
    exit 1
fi

pid_raw="$(gdbus call --session \
    --dest org.freedesktop.DBus \
    --object-path /org/freedesktop/DBus \
    --method org.freedesktop.DBus.GetConnectionUnixProcessID \
    "$owner" 2>/dev/null || true)"
pid="$(printf '%s' "$pid_raw" | grep -oE '[0-9]+' | head -n1)"

if [[ -z "$pid" || ! "$pid" =~ ^[0-9]+$ ]]; then
    notify-send "FIELD // NTF" "Could not resolve Dunst process"
    exit 1
fi

state="running"
if [[ -r "$STATE_FILE" ]]; then
    read -r state < "$STATE_FILE" || state="running"
fi

if [[ "$state" == "paused" ]]; then
    kill -USR2 "$pid" 2>/dev/null || exit 1
    printf 'running\n' > "$STATE_FILE"
    sleep 0.1
    notify-send "FIELD // NTF" "Notifications online"
else
    kill -USR1 "$pid" 2>/dev/null || exit 1
    printf 'paused\n' > "$STATE_FILE"
fi
