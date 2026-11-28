#!/bin/bash
set -eu
D=$(cd -- "$(dirname -- "$0")" && pwd)
exec python3 "$D/settings/manage.py" restore
