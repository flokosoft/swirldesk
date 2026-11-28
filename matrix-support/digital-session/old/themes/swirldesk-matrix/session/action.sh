#!/usr/bin/env bash
set -eu
ROOT="$HOME/.config/swirldesk"
[[ $(cat "$ROOT/state/current_theme_name" 2>/dev/null) == swirldesk-matrix ]] || exit 1
[[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] || { echo 'No Hyprland session' >&2; exit 1; }
run() {
    local rc
    "$@" && return 0
    rc=$?
    if command -v notify-send >/dev/null; then
        notify-send 'MATRIX // COMMAND FAILED' "${1##*/} failed (exit $rc)" || true
    fi
    return "$rc"
}
case "${1:-}" in
 lock) run hyprlock; exit $? ;;
 suspend|logout|reboot|shutdown) [[ ${2:-} == --confirmed ]] || exit 2 ;;
 *) exit 2 ;;
esac
case "$1" in
 suspend)
    # Use the existing hypridle before-sleep lock hook; refuse if it is absent.
    pgrep -u "$(id -u)" -x hypridle >/dev/null || { echo 'hypridle not running; suspend refused' >&2; if command -v notify-send >/dev/null; then notify-send 'MATRIX // SUSPEND REFUSED' 'hypridle not running' || true; fi; exit 1; }
    run loginctl lock-session
    run systemctl suspend ;;
 logout) run hyprctl dispatch exit ;;
 reboot) run systemctl reboot ;;
 shutdown) run systemctl poweroff ;;
esac
