#!/usr/bin/env bash
set -eu
HERE=$(cd -- "$(dirname -- "$0")" && pwd)
if command -v fastfetch >/dev/null && command -v kitty >/dev/null; then
    exec kitty --class matrix-system-info --title 'MATRIX SYSTEM REPORT' --hold "$HERE/fetch.sh"
fi
exec "$HOME/.config/swirldesk/scripts/system-info.sh"
