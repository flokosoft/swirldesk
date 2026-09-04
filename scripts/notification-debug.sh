#!/usr/bin/env bash
set -u

echo "FIELD // Notification diagnostics v0.2.2"
echo "---------------------------------------"
echo "dunst:    $(command -v dunst 2>/dev/null || echo missing)"
echo "dunstctl: $(command -v dunstctl 2>/dev/null || echo missing)"
echo "version:  $(dunst --version 2>/dev/null || true)"
echo "process:  $(pgrep -a -x dunst 2>/dev/null || echo 'dunst NOT running')"
echo "config symlink:"
ls -l "$HOME/.config/dunst/dunstrc" 2>&1 || true
echo "config resolved: $(readlink -f "$HOME/.config/dunst/dunstrc" 2>/dev/null || echo unresolved)"
echo "active theme:    $(readlink -f "$HOME/.config/swirldesk/state/current_theme" 2>/dev/null || echo unresolved)"
echo
if command -v gdbus >/dev/null 2>&1; then
    printf 'server:   '
    gdbus call --session --dest org.freedesktop.Notifications \
      --object-path /org/freedesktop/Notifications \
      --method org.freedesktop.Notifications.GetServerInformation 2>&1 || true
fi
printf 'dunstctl: '
dunstctl is-paused 2>&1 || true
echo

echo "FIELD colors in active config:"
grep -nE 'background|foreground|frame_color|highlight' \
  "$HOME/.config/swirldesk/state/current_theme/dunst/dunstrc" 2>/dev/null || true

echo
echo "Last dunst log lines:"
tail -n 30 "$HOME/.cache/swirldesk/dunst.log" 2>/dev/null || true
