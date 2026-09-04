#!/usr/bin/env bash
set -euo pipefail

ROOT="$HOME/.config/swirldesk"
FIELD="$ROOT/themes/swirldesk-field"
CURRENT="$ROOT/state/current_theme"

if [ ! -d "$FIELD" ]; then
    echo 'FIELD theme not found.' >&2
    exit 1
fi

# Do not silently change a non-FIELD user's active theme. If current_theme is
# FIELD (or unresolved), wire the new lockscreen and refresh the UI.
resolved=$(readlink -f "$CURRENT" 2>/dev/null || true)
if [ "$resolved" = "$FIELD" ]; then
    mkdir -p "$HOME/.config/hypr"
    ln -sfn "$FIELD/hyprlock/hyprlock.conf" "$HOME/.config/hypr/hyprlock.conf"
    chmod +x "$ROOT/scripts/"*.sh "$ROOT/link.sh" 2>/dev/null || true
    hyprctl reload >/dev/null 2>&1 || true
    "$ROOT/scripts/restart-ui.sh"
    echo 'SwirlDesk FIELD v0.3 active.'
else
    echo 'v0.3 installed. Select swirldesk-field once with SUPER+SHIFT+T to activate the theme-specific lockscreen.'
fi
