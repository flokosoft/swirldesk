#!/usr/bin/env bash
set -u
printf 'FIELD // PLASMA NOTIFICATIONS\n'
printf '%s\n' '-----------------------------'
for unit in waybar.service dunst.service; do
  st="$(systemctl --user is-enabled "$unit" 2>/dev/null || true)"
  if [[ "$st" == masked* ]]; then echo "OK      $unit masked"; else echo "WARN    $unit state: ${st:-unknown}"; fi
done
custom="$(systemctl --user is-active swirldesk-field-dunst.service 2>/dev/null || true)"
[[ "$custom" == active ]] && echo 'OK      FIELD Dunst service active' || echo "WARN    FIELD Dunst service: ${custom:-unknown}"
if pgrep -x dunst >/dev/null 2>&1; then echo 'OK      dunst process is running'; else echo 'WARN    dunst process is not running'; fi
if command -v gdbus >/dev/null 2>&1; then
  owner="$(gdbus call --session --dest org.freedesktop.DBus --object-path /org/freedesktop/DBus --method org.freedesktop.DBus.GetNameOwner org.freedesktop.Notifications 2>/dev/null | sed -n "s/.*'\([^']*\)'.*/\1/p")"
  if [[ -n "$owner" ]]; then
    pid="$(gdbus call --session --dest org.freedesktop.DBus --object-path /org/freedesktop/DBus --method org.freedesktop.DBus.GetConnectionUnixProcessID "$owner" 2>/dev/null | sed -nE 's/.*uint32[[:space:]]+([0-9]+).*/\1/p')"
    comm="$(ps -p "${pid:-0}" -o comm= 2>/dev/null | xargs || true)"
    echo "INFO    owner: ${comm:-unknown} (pid ${pid:-?})"
    [[ "$comm" == dunst ]] && echo 'OK      FIELD Dunst owns org.freedesktop.Notifications' || echo 'WARN    notification bus is not owned by FIELD Dunst'
  else
    echo 'WARN    no org.freedesktop.Notifications owner'
  fi
fi
