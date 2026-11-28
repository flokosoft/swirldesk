#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"; S="$ROOT/matrix-support"
for rel in scripts/power-menu.sh bin/swirlfetch; do
 name=${rel##*/}; dest="$ROOT/$rel"
 [[ -f "$dest" && ! -L "$dest" ]] || exit 1
 if cmp -s "$dest" "$S/$name.pre-session"; then continue; fi
 cmp -s "$dest" "$S/$name.session" && cmp -s "$S/backups/$name.pre-session" "$S/$name.pre-session" || { echo "Custom/missing backup for $rel; no changes" >&2; exit 1; }
done
for rel in scripts/power-menu.sh bin/swirlfetch; do
 name=${rel##*/}; dest="$ROOT/$rel"
 if cmp -s "$dest" "$S/$name.pre-session"; then continue; fi
 tmp=$(mktemp "$(dirname "$dest")/.matrix-session.XXXXXX"); cp -p "$S/backups/$name.pre-session" "$tmp"; mv -f "$tmp" "$dest"
done
echo 'Original dispatchers restored; MATRIX direct Waybar entry remains.'
