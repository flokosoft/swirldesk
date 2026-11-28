#!/usr/bin/env bash
set -eu
D=$(cd -- "$(dirname -- "$0")" && pwd)
python3 "$D/digital-session/manage.py" restore
