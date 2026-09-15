#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
BACKUP="${1:-$(cat "$ROOT/state/plasma_field_interaction_backup" 2>/dev/null || true)}"
if [[ -z "$BACKUP" || ! -d "$BACKUP" ]]; then
  echo 'No FIELD Plasma interaction backup found.' >&2
  exit 1
fi
for f in kglobalshortcutsrc kwinrc; do
  if [[ -f "$BACKUP/$f" ]]; then cp -a "$BACKUP/$f" "$HOME/.config/$f"; fi
done
rm -f "$HOME/.local/share/applications/org.swirldesk.field.konsole.desktop" \
      "$HOME/.local/share/applications/org.swirldesk.field.dolphin.desktop" \
      "$HOME/.local/share/applications/org.swirldesk.field.firefox.desktop"
command -v kbuildsycoca6 >/dev/null 2>&1 && kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
printf 'FIELD // PLASMA interaction restored from %s\n' "$BACKUP"
printf 'Log out and back into Plasma once to reload global shortcuts.\n'
