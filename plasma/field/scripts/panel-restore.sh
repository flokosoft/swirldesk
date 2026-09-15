#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
SRC="${1:-}"
if [[ -z "$SRC" && -f "$ROOT/state/plasma_field_panel_last_backup" ]]; then
  SRC="$(cat "$ROOT/state/plasma_field_panel_last_backup")"
fi
if [[ -z "$SRC" || ! -d "$SRC" ]]; then
  echo "No FIELD // PLASMA panel backup found." >&2
  exit 1
fi
for f in plasma-org.kde.plasma.desktop-appletsrc plasmashellrc kwinrc; do
  [[ -e "$SRC/$f" ]] && cp -a "$SRC/$f" "$HOME/.config/$f"
done
echo "FIELD // PLASMA panel config restored from: $SRC"
echo "Log out and back into Plasma for the restored panel layout to load cleanly."
