#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
BASE="$ROOT/backups/plasma-field-window"
STAMP="$(date +%Y%m%d-%H%M%S)"
DEST="$BASE/$STAMP"
mkdir -p "$DEST" "$ROOT/state"
for f in kwinrc kdeglobals breezerc; do
  [[ -e "$HOME/.config/$f" ]] && cp -a "$HOME/.config/$f" "$DEST/$f"
done
printf '%s\n' "$DEST" > "$ROOT/state/plasma_field_window_backup"
printf 'FIELD // PLASMA window backup: %s\n' "$DEST"
