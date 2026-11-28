#!/usr/bin/env bash
set -eu
D=$(cd -- "$(dirname -- "$0")" && pwd)
python3 "$D/digital-session/manage.py" doctor
T="$D/../themes/swirldesk-matrix/session/digital"
/usr/bin/python3 "$T/effect.py" --check || echo 'INFO visual effects dependencies missing'
"$T/ctl.sh" status
