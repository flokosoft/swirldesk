#!/usr/bin/env bash
set -eu
HERE=$(cd -- "$(dirname -- "$0")" && pwd)
"$HERE/guard.sh"
choice=$(printf '%s\n' 'LOCK TERMINAL' 'SUSPEND CONNECTION' 'DISCONNECT' 'REINITIALIZE' 'SYSTEM SHUTDOWN' | fuzzel --config="$HERE/../fuzzel/fuzzel.ini" --dmenu --prompt 'SESSION // ' --lines 5) || exit 0
case "$choice" in
 'LOCK TERMINAL') exec "$HERE/action.sh" lock ;;
 'SUSPEND CONNECTION') action=suspend ;;
 'DISCONNECT') action=logout ;;
 'REINITIALIZE') action=reboot ;;
 'SYSTEM SHUTDOWN') action=shutdown ;;
 *) exit 0 ;;
esac
confirm=$(printf '%s\n' CANCEL "CONFIRM $action" | fuzzel --config="$HERE/../fuzzel/fuzzel.ini" --dmenu --prompt 'VERIFY COMMAND // ' --lines 2) || exit 0
[[ $confirm == "CONFIRM $action" ]] || exit 0
exec "$HERE/action.sh" "$action" --confirmed
