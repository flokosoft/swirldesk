#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
chmod +x "$ROOT/scripts/field-status.py" "$ROOT/scripts/field-status-toggle.sh" "$ROOT/scripts/field-control-toggle.sh" 2>/dev/null || true
hyprctl reload >/dev/null 2>&1 || true
"$ROOT/scripts/restart-ui.sh" >/dev/null 2>&1 || true
printf '%s\n' 'SwirlDesk FIELD v0.9.1 active.'
printf '%s\n' 'SUPER+I: native live status panel (no full redraw / no flicker)'
printf '%s\n' 'SUPER+SPACE: reliably anchored upper-right by PID'
