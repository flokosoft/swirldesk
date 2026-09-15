#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
BACKUP="${1:-$(cat "$ROOT/state/plasma_field_dolphin_backup" 2>/dev/null || true)}"
[[ -n "$BACKUP" && -d "$BACKUP" ]] || { echo 'No FIELD Plasma Dolphin backup found.' >&2; exit 1; }

restore_or_remove() {
  local saved="$1" target="$2"
  if [[ -e "$BACKUP/$saved" ]]; then
    mkdir -p "$(dirname "$target")"
    cp -a -- "$BACKUP/$saved" "$target"
  else
    rm -f -- "$target"
  fi
}

restore_or_remove dolphinrc "$HOME/.config/dolphinrc"
restore_or_remove dolphinstaterc "$HOME/.local/state/dolphinstaterc"
restore_or_remove dolphinui.rc "$HOME/.local/share/kxmlgui5/dolphin/dolphinui.rc"
restore_or_remove dolphinui6.rc "$HOME/.local/share/kxmlgui6/dolphin/dolphinui.rc"

GLOBAL="$HOME/.local/share/dolphin/view_properties/global"
mkdir -p "$GLOBAL"
python3 - "$BACKUP/global-view-xattr.json" "$GLOBAL" <<'PY'
import base64, json, os, pathlib, sys
meta=pathlib.Path(sys.argv[1]); path=pathlib.Path(sys.argv[2]); attr=b'user.kde.fm.viewproperties#1'
if not meta.exists():
    raise SystemExit(0)
data=json.loads(meta.read_text(encoding='utf-8'))
if data.get('present'):
    os.setxattr(path, attr, base64.b64decode(data['value_b64']))
else:
    try: os.removexattr(path, attr)
    except OSError: pass
PY

if [[ -f "$BACKUP/global.directory" ]]; then
  cp -a -- "$BACKUP/global.directory" "$GLOBAL/.directory"
else
  rm -f -- "$GLOBAL/.directory"
fi

command -v kbuildsycoca6 >/dev/null 2>&1 && kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
printf 'FIELD // PLASMA Dolphin configuration restored from %s\n' "$BACKUP"
echo 'Close/reopen Dolphin to reload restored toolbar/view settings.'
