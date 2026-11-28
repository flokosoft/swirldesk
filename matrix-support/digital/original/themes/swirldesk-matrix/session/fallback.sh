#!/usr/bin/env bash
set -u
HERE=$(cd -- "$(dirname -- "$0")" && pwd)
[[ $(cat "$HOME/.config/swirldesk/state/current_theme_name" 2>/dev/null) == swirldesk-matrix ]] || exit 0
choice=$(printf '%s\n' '01 // LOCK TERMINAL' '02 // SUSPEND CONNECTION' '03 // DISCONNECT (LOGOUT)' '04 // REINITIALIZE (REBOOT)' '05 // SYSTEM SHUTDOWN' | fuzzel --dmenu --prompt 'SESSION // ' --width 45 --lines 5) || exit 0
case "$choice" in
 '01 // LOCK TERMINAL') exec "$HERE/action.sh" lock ;;
 '02 // SUSPEND CONNECTION') action=suspend ;;
 '03 // DISCONNECT (LOGOUT)') action=logout ;;
 '04 // REINITIALIZE (REBOOT)') action=reboot ;;
 '05 // SYSTEM SHUTDOWN') action=shutdown ;;
 *) exit 0 ;;
esac
confirm=$(printf '%s\n' 'CANCEL' "CONFIRM $action" | fuzzel --dmenu --prompt 'VERIFY COMMAND // ' --width 45 --lines 2) || exit 0
[[ "$confirm" == "CONFIRM $action" ]] || exit 0
exec "$HERE/action.sh" "$action" --confirmed
