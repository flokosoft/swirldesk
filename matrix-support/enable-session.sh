#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"; S="$ROOT/matrix-support"
for rel in scripts/power-menu.sh bin/swirlfetch; do
    name=${rel##*/}; dest="$ROOT/$rel"
    [[ -f "$dest" && ! -L "$dest" ]] || { echo "Missing/nonregular $rel; no dispatcher changes" >&2; exit 1; }
    if ! cmp -s "$dest" "$S/$name.pre-session" && ! cmp -s "$dest" "$S/$name.session"; then echo "Custom $rel; no dispatcher changes" >&2; exit 1; fi
    bash -n "$S/$name.session"
    if [[ -e "$S/backups/$name.pre-session" ]]; then cmp -s "$S/backups/$name.pre-session" "$S/$name.pre-session" || { echo 'Backup mismatch' >&2; exit 1; }; fi
done
mkdir -p "$S/backups"
for rel in scripts/power-menu.sh bin/swirlfetch; do
    name=${rel##*/}; dest="$ROOT/$rel"
    cmp -s "$dest" "$S/$name.session" && continue
    [[ -e "$S/backups/$name.pre-session" ]] || cp -p "$dest" "$S/backups/$name.pre-session"
    tmp=$(mktemp "$(dirname "$dest")/.matrix-session.XXXXXX"); install -m 755 "$S/$name.session" "$tmp"; mv -f "$tmp" "$dest"
done
echo 'MATRIX session integration enabled; reselect MATRIX.'
