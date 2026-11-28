#!/usr/bin/env bash
set -eu
ROOT="$HOME/.config/swirldesk"
case "${XDG_CURRENT_DESKTOP:-};${XDG_SESSION_DESKTOP:-}" in *KDE*|*plasma*|*Plasma*) ;; *) exit 1 ;; esac
[[ -z ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] || exit 1
python3 - "$ROOT/state/plasma_matrix/active.json" <<'PY'
import json,sys
try: sys.exit(0 if json.load(open(sys.argv[1]))['status']=='active' else 1)
except (OSError,ValueError,KeyError): sys.exit(1)
PY
