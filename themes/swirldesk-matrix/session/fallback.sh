#!/usr/bin/env bash
set -u
HERE=$(cd -- "$(dirname -- "$0")" && pwd)
[[ $(cat "$HOME/.config/swirldesk/state/current_theme_name" 2>/dev/null) == swirldesk-matrix ]] || exit 0
choice=$(printf '%s\n' 'lock session' 'suspend computer' 'log out' 'restart' 'power off' | fuzzel --dmenu --prompt 'session > ' --width 45 --lines 5) || exit 0
case "$choice" in
 'lock session') exec "$HERE/action.sh" lock ;;
 'suspend computer') action=suspend ;;
 'log out') action=logout ;;
 'restart') action=reboot ;;
 'power off') action=shutdown ;;
 *) exit 0 ;;
esac
confirm=$(printf '%s\n' 'CANCEL' "CONFIRM $action" | fuzzel --dmenu --prompt 'VERIFY COMMAND // ' --width 45 --lines 2) || exit 0
[[ "$confirm" == "CONFIRM $action" ]] || exit 0
exec "$HERE/action.sh" "$action" --confirmed
