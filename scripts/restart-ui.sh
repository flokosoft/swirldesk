#!/usr/bin/env bash
set -u

pkill -x waybar 2>/dev/null || true
pkill -x swaybg 2>/dev/null || true

"$HOME/.config/swirldesk/scripts/ui-start.sh"

# Do not use dunstctl as the only readiness probe: on some Debian/Wayland
# sessions Dunst serves org.freedesktop.Notifications while its private control
# interface is not reachable.
sleep 0.35
online=0
if command -v gdbus >/dev/null 2>&1; then
    out=$(gdbus call --session \
        --dest org.freedesktop.DBus \
        --object-path /org/freedesktop/DBus \
        --method org.freedesktop.DBus.NameHasOwner \
        org.freedesktop.Notifications 2>/dev/null || true)
    [[ "$out" == *true* ]] && online=1
elif pgrep -x dunst >/dev/null 2>&1; then
    online=1
fi

if (( online )); then
    notify-send 'UI // ONLINE' 'SwirlDesk FIELD interface ready'
fi
