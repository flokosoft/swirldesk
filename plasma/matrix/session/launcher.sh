#!/usr/bin/env bash
set -eu
HERE=$(cd -- "$(dirname -- "$0")" && pwd)
"$HERE/guard.sh"
if command -v fuzzel >/dev/null; then exec fuzzel --config="$HERE/../fuzzel/fuzzel.ini"; fi
exec krunner
