#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
S="$ROOT/matrix-support"
D="$ROOT/scripts/theme-switcher.sh"
SRC="$S/theme-switcher.sh.profiles"
B="$S/backups/theme-switcher.sh.pre-profiles"
[[ -f "$D" && ! -L "$D" ]] || { echo 'Theme switcher not a regular file; refusing changes.' >&2; exit 1; }
actual=$(sha256sum "$D" | cut -d' ' -f1)
case "$actual" in
 a8c500253ca692d5418f963c911ae603ddb409bcb96da550834aa5335c33ca6c) echo 'MATRIX profiles already enabled'; exit 0;;
 a53074b5cf2acdbc02c98645d7cf89faebea00aba5b5afa92adfa0d843bb7e06|b38c676bdd033c5f3a8d82da514d9e37a36401cdd1761ca60c5c48ee56936a6e) ;;
 *) echo 'Theme switcher differs from known baseline; unchanged. Manual profiles still work.' >&2; exit 1;;
esac
[[ $(sha256sum "$SRC" | cut -d' ' -f1) == a8c500253ca692d5418f963c911ae603ddb409bcb96da550834aa5335c33ca6c ]] || { echo 'Template integrity mismatch' >&2; exit 1; }
bash -n "$SRC"
mkdir -p "$S/backups"
if [[ -e "$B" ]]; then cmp -s "$B" "$D" || { echo 'Existing backup differs; no change.' >&2; exit 1; }; else cp -p "$D" "$B"; fi
TMP=$(mktemp "$ROOT/scripts/.matrix-profiles.XXXXXX")
trap 'rm -f "$TMP"' EXIT
install -m 755 "$SRC" "$TMP"
mv -f "$TMP" "$D"
echo 'MATRIX profiles enabled. Re-select MATRIX through Super+Shift+T.'
