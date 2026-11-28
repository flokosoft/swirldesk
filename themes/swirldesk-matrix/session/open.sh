#!/usr/bin/env bash
set -u
HERE=$(cd -- "$(dirname -- "$0")" && pwd)
[[ $(cat "$HOME/.config/swirldesk/state/current_theme_name" 2>/dev/null) == swirldesk-matrix ]] || exit 0
[[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] || exit 0
if python3 -c 'import gi; gi.require_version("Gtk", "3.0"); from gi.repository import Gtk' 2>/dev/null; then
    exec python3 "$HERE/power.py"
fi
exec "$HERE/fallback.sh"
