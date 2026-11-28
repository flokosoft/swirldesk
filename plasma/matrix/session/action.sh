#!/usr/bin/env bash
set -euo pipefail
HERE=$(cd -- "$(dirname -- "$0")" && pwd)
"$HERE/guard.sh"
q=''
for c in qdbus6 qdbus-qt6 qdbus; do if command -v "$c" >/dev/null; then q=$c; break; fi; done
[[ -n $q ]] || { echo 'No Qt D-Bus client' >&2; exit 1; }
case "${1:-}" in lock) exec "$q" org.freedesktop.ScreenSaver /ScreenSaver org.freedesktop.ScreenSaver.Lock ;; suspend|logout|reboot|shutdown) [[ ${2:-} == --confirmed ]] || exit 2 ;; *) exit 2 ;; esac
# KDE owns logout and power confirmations, rather than terminating applications directly.
case "$1" in
 logout) exec "$q" org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptLogout ;;
 reboot) exec "$q" org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptReboot ;;
 shutdown) exec "$q" org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptShutdown ;;
 suspend)
   "$q" org.freedesktop.ScreenSaver /ScreenSaver org.freedesktop.ScreenSaver.Lock
   for _ in {1..30}; do
     if [[ $("$q" org.freedesktop.ScreenSaver /ScreenSaver org.freedesktop.ScreenSaver.GetActive 2>/dev/null || true) == true ]]; then exec systemctl suspend; fi
     sleep .1
   done
   notify-send 'MATRIX // SUSPEND REFUSED' 'Screen lock could not be verified' 2>/dev/null || true
   exit 1 ;;
esac
