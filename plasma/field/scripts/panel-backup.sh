#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
STAMP="$(date +%Y%m%d-%H%M%S)"
DEST="$ROOT/backups/plasma-field-panel/$STAMP"
mkdir -p "$DEST"
for f in plasma-org.kde.plasma.desktop-appletsrc plasmashellrc kwinrc; do
  if [[ -e "$HOME/.config/$f" || -L "$HOME/.config/$f" ]]; then
    cp -a "$HOME/.config/$f" "$DEST/"
  fi
done
printf '%s\n' "$DEST" > "$ROOT/state/plasma_field_panel_last_backup"
echo "FIELD // PLASMA panel backup: $DEST"
