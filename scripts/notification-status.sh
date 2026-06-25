#!/usr/bin/env bash
set -euo pipefail

if ! command -v dunstctl >/dev/null 2>&1; then
    printf '{"text":"󰂛 ?","tooltip":"dunstctl nicht gefunden","class":"unknown"}\n'
    exit 0
fi

if [ "$(dunstctl is-paused)" = "true" ]; then
    printf '{"text":"󰂛 still","tooltip":"Benachrichtigungen pausiert","class":"paused"}\n'
else
    printf '{"text":"󰂚 aktiv","tooltip":"Benachrichtigungen aktiv","class":"active"}\n'
fi
