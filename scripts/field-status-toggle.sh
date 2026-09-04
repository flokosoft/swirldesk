#!/usr/bin/env bash
set -u
ROOT="$HOME/.config/swirldesk"
TITLE='FIELD STATUS'

# Toggle an existing status panel off.
if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    addr=$(hyprctl clients -j 2>/dev/null | jq -r ".[] | select(.title == \"$TITLE\" or .class == \"field-status\" or .class == \"swirldesk-field-status\") | .address" | head -n1)
    if [ -n "${addr:-}" ] && [ "$addr" != 'null' ]; then
        hyprctl dispatch closewindow "address:$addr" >/dev/null 2>&1 || true
        exit 0
    fi
fi

native=0
if python3 - <<'PY' >/dev/null 2>&1
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk
PY
then
    python3 "$ROOT/scripts/field-status.py" >/dev/null 2>&1 &
    app_pid=$!
    native=1
else
    kitty \
        --class field-status \
        --title "$TITLE" \
        --override hide_window_decorations=yes \
        --override background_opacity=0.992 \
        --override window_padding_width=13 \
        --override font_size=10.2 \
        --override confirm_os_window_close=0 \
        -e "$ROOT/scripts/field-status.sh" >/dev/null 2>&1 &
    app_pid=$!
fi

# Place the actual new client by PID, not by a timing-sensitive title match.
# This is more reliable and keeps the panel at the upper-right edge.
if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    for _ in $(seq 1 60); do
        sleep 0.05
        client=$(hyprctl clients -j 2>/dev/null | jq -c --argjson pid "$app_pid" '.[] | select(.pid == $pid)' | head -n1)
        [ -n "${client:-}" ] || continue
        addr=$(printf '%s' "$client" | jq -r '.address')
        mon_id=$(printf '%s' "$client" | jq -r '.monitor')
        mon=$(hyprctl monitors -j 2>/dev/null | jq -c ".[] | select(.id == $mon_id)" | head -n1)
        [ -n "${mon:-}" ] || break
        mx=$(printf '%s' "$mon" | jq -r '.x')
        my=$(printf '%s' "$mon" | jq -r '.y')
        mw=$(printf '%s' "$mon" | jq -r '.width')
        width=550
        x=$((mx + mw - width - 14))
        y=$((my + 44))
        hyprctl dispatch movewindowpixel "exact $x $y,address:$addr" >/dev/null 2>&1 || true
        break
    done
fi
