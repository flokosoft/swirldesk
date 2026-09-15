#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
SRC="${1:-}"
if [[ -z "$SRC" && -f "$ROOT/state/plasma_field_last_backup" ]]; then
  SRC="$(cat "$ROOT/state/plasma_field_last_backup")"
fi
if [[ -z "$SRC" || ! -d "$SRC" ]]; then
  echo "No Plasma backup found. Pass a backup directory explicitly." >&2
  exit 1
fi
for p in "$SRC"/config/*; do
  [[ -e "$p" ]] || continue
  cp -a "$p" "$HOME/.config/"
done
if [[ -e "$SRC/gtk-3.0/colors.css" ]]; then
  mkdir -p "$HOME/.config/gtk-3.0"
  cp -a "$SRC/gtk-3.0/colors.css" "$HOME/.config/gtk-3.0/colors.css"
fi
echo "FIELD // PLASMA restored from: $SRC"
echo "Log out and back into Plasma for a clean reload."
