#!/usr/bin/env bash
set -u
ROOT="$HOME/.config/swirldesk"
THEME="$(cat "$ROOT/state/current_theme_name" 2>/dev/null || true)"

# FIELD gets the native GTK control panel. Other themes keep the established
# Fuzzel menu, so the SwirlDesk core remains reversible/theme-neutral.
if [ "$THEME" = "swirldesk-field" ]; then
    exec "$ROOT/scripts/field-control-toggle.sh"
fi
exec "$ROOT/scripts/control-center-fallback.sh"
