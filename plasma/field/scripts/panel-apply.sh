#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
FIELD="$ROOT/plasma/field"
SCRIPT="$FIELD/panel/layout.js"

if ! pgrep -x plasmashell >/dev/null 2>&1; then
  echo 'FIELD // PLASMA panel can only be applied inside a Plasma session.' >&2
  exit 1
fi

QDBUS=''
for c in qdbus6 qdbus qdbus-qt6; do
  if command -v "$c" >/dev/null 2>&1; then QDBUS="$c"; break; fi
done
if [[ -z "$QDBUS" ]]; then
  echo 'No qdbus client found. Install the Qt 6 DBus tools first.' >&2
  exit 1
fi

"$FIELD/scripts/panel-doctor.sh"
"$FIELD/scripts/panel-backup.sh"

# Official Plasma scripting interface. This changes only panel containments.
"$QDBUS" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat "$SCRIPT")"

printf '\nFIELD // PLASMA RAIL APPLIED\n'
printf '  location   TOP\n'
printf '  height     30 px\n'
printf '  layout     launcher | pager | tasks | spacer | tray | time\n'
printf '  floating   no\n\n'
printf 'If anything is wrong: swirl-field plasma panel restore\n'
