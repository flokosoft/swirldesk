#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
S="$ROOT/matrix-support"
D="$ROOT/scripts/control-center.sh"
B="$S/backups/control-center.sh.original"
if cmp -s "$D" "$S/control-center.sh.original"; then echo 'Original dispatcher already active'; exit 0; fi
cmp -s "$D" "$S/control-center.sh.matrix" && cmp -s "$B" "$S/control-center.sh.original" || { echo 'Dispatcher or backup differs; no changes made.' >&2; exit 1; }
TMP=$(mktemp "$ROOT/scripts/.matrix-operator.XXXXXX")
trap 'rm -f "$TMP"' EXIT
install -m 755 "$B" "$TMP"
mv -f "$TMP" "$D"
echo 'Original dispatcher restored.'
