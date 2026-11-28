#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
DEST="$ROOT/scripts/theme-switcher.sh"
BACKUP="$ROOT/matrix-support/backups/theme-switcher.sh.original"
[ "$(sha256sum "$DEST" | cut -d' ' -f1)" = 'b38c676bdd033c5f3a8d82da514d9e37a36401cdd1761ca60c5c48ee56936a6e' ] || { echo 'Theme switcher changed; refusing overwrite' >&2; exit 1; }
[ "$(sha256sum "$BACKUP" | cut -d' ' -f1)" = 'a53074b5cf2acdbc02c98645d7cf89faebea00aba5b5afa92adfa0d843bb7e06' ] || { echo 'Backup mismatch; refusing overwrite' >&2; exit 1; }
cp -p "$BACKUP" "$DEST"
echo 'Original theme switcher restored'
