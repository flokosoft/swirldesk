#!/usr/bin/env bash
set -u
ROOT="$HOME/.config/swirldesk"
TITLE='FIELD KEYMAP'

if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    addr=$(hyprctl clients -j 2>/dev/null | jq -r ".[] | select(.title == \"$TITLE\") | .address" | head -n1)
    if [ -n "${addr:-}" ] && [ "$addr" != 'null' ]; then
        hyprctl dispatch closewindow "address:$addr" >/dev/null 2>&1 || true
        exit 0
    fi
fi

if ! python3 - <<'PY' >/dev/null 2>&1
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk
PY
then
    exec "$ROOT/scripts/keybinds-help-fallback.sh"
fi

exec python3 "$ROOT/scripts/field-keymap.py"
