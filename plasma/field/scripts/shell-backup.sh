#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
STAMP="$(date +%Y%m%d-%H%M%S)"
DEST="$ROOT/backups/plasma-field-shell-$STAMP"
mkdir -p "$DEST"
for f in kscreenlockerrc plasmarc krunnerrc; do
  [[ -f "$HOME/.config/$f" ]] && cp -a "$HOME/.config/$f" "$DEST/$f"
done
printf '%s\n' "$DEST" > "$ROOT/state/plasma_field_shell_backup"
echo "$DEST"
