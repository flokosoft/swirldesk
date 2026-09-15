#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
STAMP="$(date +%Y%m%d-%H%M%S)"
DEST="$ROOT/backups/plasma-field/$STAMP"
mkdir -p "$DEST/config" "$DEST/gtk-3.0"

files=(
  kdeglobals kwinrc plasmarc plasma-org.kde.plasma.desktop-appletsrc
  kscreenlockerrc kcminputrc kglobalshortcutsrc dolphinrc konsolerc
)
for f in "${files[@]}"; do
  if [[ -e "$HOME/.config/$f" || -L "$HOME/.config/$f" ]]; then
    cp -a "$HOME/.config/$f" "$DEST/config/"
  fi
done
if [[ -e "$HOME/.config/gtk-3.0/colors.css" ]]; then
  cp -a "$HOME/.config/gtk-3.0/colors.css" "$DEST/gtk-3.0/"
fi
printf '%s\n' "$DEST" > "$ROOT/state/plasma_field_last_backup" 2>/dev/null || {
  mkdir -p "$ROOT/state"; printf '%s\n' "$DEST" > "$ROOT/state/plasma_field_last_backup";
}
echo "FIELD // PLASMA backup: $DEST"
