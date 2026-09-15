#!/usr/bin/env bash
set -u
ROOT="$HOME/.config/swirldesk"
SCRIPT="$ROOT/plasma/field/scripts/plasma-power.py"
pid="$(pgrep -f "python3 .*plasma-power.py" | head -n1 || true)"
if [[ -n "$pid" ]]; then
  kill "$pid" 2>/dev/null || true
  exit 0
fi
# FIELD 0.8.3 already centered correctly for this setup by running GTK3 via
# XWayland. Keep that proven path; do not try to reposition the Wayland window.
if [[ -n "${DISPLAY:-}" ]]; then
  exec env GDK_BACKEND=x11 python3 "$SCRIPT"
else
  exec python3 "$SCRIPT"
fi
