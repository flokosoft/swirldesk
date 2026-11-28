#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
DEST="$ROOT/scripts/theme-switcher.sh"
SRC="$ROOT/matrix-support/theme-switcher.sh.matrix"
actual="$(sha256sum "$DEST" | cut -d' ' -f1)"
case "$actual" in
    b38c676bdd033c5f3a8d82da514d9e37a36401cdd1761ca60c5c48ee56936a6e) echo 'MATRIX wallpaper restore already installed'; exit 0 ;;
    a53074b5cf2acdbc02c98645d7cf89faebea00aba5b5afa92adfa0d843bb7e06) ;;
    *) echo 'Theme switcher differs from supplied baseline; no file changed.' >&2; exit 1 ;;
esac
mkdir -p "$ROOT/matrix-support/backups"
backup="$ROOT/matrix-support/backups/theme-switcher.sh.original"
if [ -e "$backup" ]; then
    [ "$(sha256sum "$backup" | cut -d' ' -f1)" = 'a53074b5cf2acdbc02c98645d7cf89faebea00aba5b5afa92adfa0d843bb7e06' ] || { echo 'Existing backup differs; aborting' >&2; exit 1; }
else
    cp -p "$DEST" "$backup"
fi
bash -n "$SRC"
tmp="$(mktemp "$ROOT/scripts/.matrix-switcher.XXXXXX")"
trap 'rm -f "$tmp"' EXIT
install -m 755 "$SRC" "$tmp"
mv -f "$tmp" "$DEST"
echo "MATRIX wallpaper restore enabled; original: $backup"
