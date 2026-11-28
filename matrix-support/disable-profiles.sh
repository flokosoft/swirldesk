#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
S="$ROOT/matrix-support"
D="$ROOT/scripts/theme-switcher.sh"
B="$S/backups/theme-switcher.sh.pre-profiles"
[[ $(sha256sum "$D" | cut -d' ' -f1) == a8c500253ca692d5418f963c911ae603ddb409bcb96da550834aa5335c33ca6c ]] || { echo 'Theme switcher changed; refusing overwrite.' >&2; exit 1; }
case "$(sha256sum "$B" | cut -d' ' -f1)" in
 a53074b5cf2acdbc02c98645d7cf89faebea00aba5b5afa92adfa0d843bb7e06|b38c676bdd033c5f3a8d82da514d9e37a36401cdd1761ca60c5c48ee56936a6e) ;;
 *) echo 'Backup mismatch; refusing overwrite.' >&2; exit 1;;
esac
TMP=$(mktemp "$ROOT/scripts/.matrix-profiles.XXXXXX")
trap 'rm -f "$TMP"' EXIT
cp -p "$B" "$TMP"
mv -f "$TMP" "$D"
echo 'Pre-profiles theme switcher restored. Manual profile selector remains available.'
