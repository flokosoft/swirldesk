#!/usr/bin/env bash
set -u
ROOT="$HOME/.config/swirldesk"
TITLE='FIELD CONTROL'

# Toggle an existing panel off.
if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    addr=$(hyprctl clients -j 2>/dev/null | jq -r ".[] | select(.title == \"$TITLE\") | .address" | head -n1)
    if [ -n "${addr:-}" ] && [ "$addr" != 'null' ]; then
        hyprctl dispatch closewindow "address:$addr" >/dev/null 2>&1 || true
        exit 0
    fi
fi

# Native GTK panel when available; preserve Fuzzel fallback.
if ! python3 - <<'PY' >/dev/null 2>&1
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk
PY
then
    command -v notify-send >/dev/null 2>&1 && \
        notify-send 'FIELD // CONTROL' 'GTK control panel unavailable; using compact fallback.'
    exec "$ROOT/scripts/control-center-fallback.sh"
fi

python3 "$ROOT/scripts/field-control.py" >/dev/null 2>&1 &
app_pid=$!

# FIELD CONTROL is intentionally centered. Hyprland's field-control window rule
# handles the position; unlike FIELD STATUS it must not be edge-anchored.
exit 0
