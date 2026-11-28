#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"; S="$ROOT/matrix-support"; T="$ROOT/themes/swirldesk-matrix"
D="$ROOT/scripts/theme-switcher.sh"; SRC="$S/theme-switcher.sh.icons"; B="$S/backups/theme-switcher.sh.pre-icons"
LINK="$HOME/.local/share/icons/SwirlDesk-MATRIX"; TARGET="$T/icons/SwirlDesk-MATRIX"
[[ -f "$D" && ! -L "$D" ]] || { echo 'Unknown theme switcher; refusing.' >&2; exit 1; }
if ! cmp -s "$D" "$SRC" && ! cmp -s "$D" "$S/theme-switcher.sh.profiles"; then
    echo 'Theme switcher differs from v0.3.0; no switcher or icon-link changes made.' >&2; exit 1
fi
[[ -s "$TARGET/index.theme" ]] || { echo 'Missing icon theme' >&2; exit 1; }
bash -n "$SRC"
if [[ -e "$LINK" || -L "$LINK" ]]; then
    [[ -L "$LINK" && $(readlink -f "$LINK") == "$TARGET" ]] || { echo 'Existing icon theme is not our link; refusing to replace.' >&2; exit 1; }
fi
mkdir -p "$S/backups" "$(dirname "$LINK")"
if ! cmp -s "$D" "$SRC"; then
    if [[ -e "$B" ]]; then cmp -s "$B" "$D" || { echo 'Backup mismatch; refusing.' >&2; exit 1; }; else cp -p "$D" "$B"; fi
fi
[[ -L "$LINK" ]] || ln -s "$TARGET" "$LINK"
if ! cmp -s "$D" "$SRC"; then
    TMP=$(mktemp "$ROOT/scripts/.matrix-icons.XXXXXX"); trap 'rm -f "$TMP"' EXIT
    install -m 755 "$SRC" "$TMP"; mv -f "$TMP" "$D"
fi
echo 'MATRIX icon integration enabled. Re-select MATRIX through Super+Shift+T.'
