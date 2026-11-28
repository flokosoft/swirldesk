#!/usr/bin/env bash
set -euo pipefail
[[ $EUID -ne 0 ]] || { echo 'Nicht mit sudo starten (nur apt verwendet sudo).'; exit 1; }
ROOT=$(cd -- "$(dirname -- "$0")" && pwd -P)
exec python3 "$ROOT/master/install.py" "$@"
