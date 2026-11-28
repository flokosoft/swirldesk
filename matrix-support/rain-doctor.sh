#!/usr/bin/env bash
set -uo pipefail
D=$(cd "$(dirname "$0")" && pwd)
python3 "$D/rain/manage.py" doctor; result=$?
"$D/../themes/swirldesk-matrix/visual/rain/ctl.sh" doctor
exit "$result"
