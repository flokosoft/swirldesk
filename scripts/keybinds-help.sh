#!/usr/bin/env bash
set -u
ROOT="$HOME/.config/swirldesk"
THEME="$(cat "$ROOT/state/current_theme_name" 2>/dev/null || true)"

if [ "$THEME" = "swirldesk-field" ]; then
    exec "$ROOT/scripts/field-keymap-toggle.sh"
fi
exec "$ROOT/scripts/keybinds-help-fallback.sh"
