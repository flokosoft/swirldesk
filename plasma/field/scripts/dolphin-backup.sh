#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
BASE="$ROOT/backups/plasma-field-dolphin"
STAMP="$(date +%Y%m%d-%H%M%S)"
DEST="$BASE/$STAMP"
mkdir -p "$DEST" "$ROOT/state"

copy_if_exists() {
  local src="$1" name="$2"
  if [[ -e "$src" ]]; then
    cp -a -- "$src" "$DEST/$name"
  fi
  return 0
}

copy_if_exists "$HOME/.config/dolphinrc" dolphinrc
copy_if_exists "$HOME/.local/state/dolphinstaterc" dolphinstaterc
copy_if_exists "$HOME/.local/share/kxmlgui5/dolphin/dolphinui.rc" dolphinui.rc
copy_if_exists "$HOME/.local/share/kxmlgui6/dolphin/dolphinui.rc" dolphinui6.rc

# Dolphin 24.12+ stores global view properties as an xattr on this directory.
python3 - "$DEST" "$HOME/.local/share/dolphin/view_properties/global" <<'PY'
import base64, json, os, pathlib, sys
backup = pathlib.Path(sys.argv[1]) / "global-view-xattr.json"
path = pathlib.Path(sys.argv[2])
attr = b"user.kde.fm.viewproperties#1"
data = {"path": str(path), "present": False, "value_b64": ""}
try:
    value = os.getxattr(path, attr)
except (FileNotFoundError, OSError):
    pass
else:
    data["present"] = True
    data["value_b64"] = base64.b64encode(value).decode("ascii")
backup.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY

# Keep a fallback .directory too if one already exists.
copy_if_exists "$HOME/.local/share/dolphin/view_properties/global/.directory" global.directory

printf '%s\n' "$DEST" > "$ROOT/state/plasma_field_dolphin_backup"
printf 'FIELD // PLASMA Dolphin backup: %s\n' "$DEST"
