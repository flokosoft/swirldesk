#!/usr/bin/env bash
D=$(cd -- "$(dirname -- "$0")" && pwd)
"$D/ctl.sh" kick >/dev/null 2>&1 || true
exec "$D/../../visual/profile.sh" --status
