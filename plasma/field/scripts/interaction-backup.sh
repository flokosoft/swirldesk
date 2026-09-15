#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
BASE="$ROOT/backups/plasma-field-interaction"
STAMP="$(date +%Y%m%d-%H%M%S)"
DEST="$BASE/$STAMP"
mkdir -p "$DEST" "$ROOT/state"
for f in kglobalshortcutsrc kwinrc; do
  if [[ -e "$HOME/.config/$f" ]]; then
    cp -a "$HOME/.config/$f" "$DEST/$f"
  fi
done
printf '%s\n' "$DEST" > "$ROOT/state/plasma_field_interaction_backup"
printf 'FIELD // PLASMA interaction backup: %s\n' "$DEST"
