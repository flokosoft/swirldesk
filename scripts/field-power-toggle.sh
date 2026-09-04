#!/usr/bin/env bash
set -u
ROOT="$HOME/.config/swirldesk"
TITLE='FIELD POWER'

if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    addr=$(hyprctl clients -j 2>/dev/null | jq -r ".[] | select(.title == \"$TITLE\" or .class == \"swirldesk-field-power\") | .address" | head -n1)
    if [ -n "${addr:-}" ] && [ "$addr" != 'null' ]; then
        hyprctl dispatch closewindow "address:$addr" >/dev/null 2>&1 || true
        exit 0
    fi
fi

exec python3 "$ROOT/scripts/field-power.py"
