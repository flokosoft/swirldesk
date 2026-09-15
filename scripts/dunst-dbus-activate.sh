#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
CONF="$ROOT/state/current_theme/dunst/dunstrc"
[[ -r "$CONF" ]] || CONF="$ROOT/themes/swirldesk-field/dunst/dunstrc"
[[ -r "$CONF" ]] || CONF="$HOME/.config/dunst/dunstrc"
[[ -r "$CONF" ]] || exit 1
exec /usr/bin/dunst --config "$(readlink -f "$CONF" 2>/dev/null || printf '%s' "$CONF")"
