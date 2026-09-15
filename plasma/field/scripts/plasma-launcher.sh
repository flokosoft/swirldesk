#!/usr/bin/env bash
set -euo pipefail
CFG="$HOME/.config/swirldesk/plasma/field/fuzzel/fuzzel.ini"

# FIELD // QUICK LAUNCH
# Mirrors the Hyprland SUPER+CTRL+RETURN launcher: a small centered searchable
# XDG application picker. On Plasma we intentionally keep Meta+Space for KRunner.
if command -v fuzzel >/dev/null 2>&1; then
    exec fuzzel --config="$CFG"
fi

# Graceful fallback when a minimal Plasma install does not have fuzzel.
if command -v krunner >/dev/null 2>&1; then
    exec krunner
fi

notify-send "FIELD // RUN" "No launcher available (install fuzzel)." 2>/dev/null || true
exit 1
