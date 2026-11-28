#!/usr/bin/env bash
set -euo pipefail
D=$(cd -- "$(dirname -- "$0")" && pwd)
python3 "$D/crt/manage.py" doctor
"$D/../themes/swirldesk-matrix/visual/crt/ctl.sh" status
