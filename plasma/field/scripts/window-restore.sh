#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
BACKUP="${1:-$(cat "$ROOT/state/plasma_field_window_backup" 2>/dev/null || true)}"
[[ -n "$BACKUP" && -d "$BACKUP" ]] || { echo 'No FIELD Plasma window backup found.' >&2; exit 1; }
for f in kwinrc kdeglobals breezerc; do
  [[ -f "$BACKUP/$f" ]] && cp -a "$BACKUP/$f" "$HOME/.config/$f"
done
QDBUS=''
for c in qdbus6 qdbus qdbus-qt6; do command -v "$c" >/dev/null 2>&1 && { QDBUS="$c"; break; }; done
[[ -n "$QDBUS" ]] && "$QDBUS" org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
printf 'FIELD // PLASMA window configuration restored from %s\n' "$BACKUP"
