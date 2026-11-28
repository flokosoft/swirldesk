#!/usr/bin/env bash
set -euo pipefail
D=$(cd -- "$(dirname -- "$0")" && pwd)
python3 "$D/crt/manage.py" restore
