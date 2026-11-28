#!/usr/bin/env bash
set -euo pipefail
D=$(cd "$(dirname "$0")" && pwd)
python3 "$D/rain/manage.py" apply
"$D/../themes/swirldesk-matrix/visual/rain/ctl.sh" doctor
