#!/usr/bin/env bash
set -u
HERE="$(cd -- "$(dirname -- "$0")" && pwd)"
ROOT="$HOME/.config/swirldesk"
[ "$(cat "$ROOT/state/current_theme_name" 2>/dev/null)" = swirldesk-matrix ] || exit 0
if python3 -c 'import gi; gi.require_version("Gtk", "3.0"); from gi.repository import Gtk' 2>/dev/null; then
    if python3 "$HERE/matrix_operator.py"; then exit 0; fi
fi
exec bash "$HERE/fallback.sh"
