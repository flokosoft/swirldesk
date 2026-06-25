#!/usr/bin/env bash
set -euo pipefail

if ! command -v dunstctl >/dev/null 2>&1; then
    notify-send "SwirlDesk" "dunstctl wurde nicht gefunden"
    exit 1
fi

STATUS="$(dunstctl is-paused)"

if [ "$STATUS" = "true" ]; then
    dunstctl set-paused false
    notify-send "SwirlDesk" "Benachrichtigungen aktiviert"
else
    dunstctl set-paused true
fi
