#!/usr/bin/env bash
set -eu
HERE=$(cd -- "$(dirname -- "$0")" && pwd)
exec fastfetch --config "$HERE/fastfetch.jsonc" --logo "$HERE/logo.txt" "$@"
