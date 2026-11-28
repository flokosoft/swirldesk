#!/bin/bash
set -u
D=$(cd -- "$(dirname -- "$0")" && pwd)
rc=0
check() { printf '\n--- %s ---\n' "$1"; shift; "$@" || { echo 'MISMATCH check returned nonzero'; rc=1; }; }
check 'settings integration' python3 "$D/settings/manage.py" doctor
check 'foundation / icons / session' bash "$D/doctor.sh"
check 'digital appearance' python3 "$D/digital/manage.py" doctor
check 'rain' bash "$D/rain-doctor.sh"
check 'CRT' bash "$D/crt-doctor.sh"
check 'digital session' bash "$D/session-doctor.sh"
check 'saved preferences' python3 "$D/../themes/swirldesk-matrix/settings/settings.py" status
printf '\nMATRIX v0.9.1: exit status %s (inspect individual INFO/MISMATCH lines; older doctors may only report textual warnings)\n' "$rc"
exit "$rc"
