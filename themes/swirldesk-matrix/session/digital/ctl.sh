#!/usr/bin/env bash
set -eu
D=$(cd -- "$(dirname -- "$0")" && pwd)
exec /usr/bin/python3 "$D/controller.py" "$@"
