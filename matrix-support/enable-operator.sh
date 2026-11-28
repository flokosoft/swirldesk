#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
D="$ROOT/scripts/control-center.sh"
S="$ROOT/matrix-support"
# Compare actual bytes against the original archive, never overwrite custom edits.
if cmp -s "$D" "$S/control-center.sh.matrix"; then
    echo 'MATRIX operator shortcut already enabled'; exit 0
fi
if ! cmp -s "$D" "$S/control-center.sh.original"; then
    echo 'Control-center dispatcher differs from baseline; no changes made. Waybar/direct launch still works.' >&2; exit 1
fi
bash -n "$S/control-center.sh.matrix"
mkdir -p "$S/backups"
B="$S/backups/control-center.sh.original"
if [ -e "$B" ]; then cmp -s "$B" "$D" || { echo 'Backup mismatch; aborting' >&2; exit 1; }; else cp -p "$D" "$B"; fi
TMP=$(mktemp "$ROOT/scripts/.matrix-operator.XXXXXX")
trap 'rm -f "$TMP"' EXIT
install -m 755 "$S/control-center.sh.matrix" "$TMP"
mv -f "$TMP" "$D"
echo 'MATRIX operator enabled: Super+Space; other themes unchanged.'
