#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"; S="$ROOT/matrix-support"; T="$ROOT/themes/swirldesk-matrix"
D="$ROOT/scripts/theme-switcher.sh"; B="$S/backups/theme-switcher.sh.pre-icons"
if [[ $(cat "$ROOT/state/current_theme_name" 2>/dev/null || true) == swirldesk-matrix ]]; then
    echo 'Select FIELD/Debian/Graphite before rollback.' >&2; exit 1
fi
cmp -s "$D" "$S/theme-switcher.sh.icons" && cmp -s "$B" "$S/theme-switcher.sh.profiles" || { echo 'Switcher/backup differs; no change.' >&2; exit 1; }
# Only restore shipped config files if they still match the release checksums.
(cd "$ROOT" && sha256sum --status -c "$S/icons-config.sha256") || { echo 'MATRIX configuration changed; refusing rollback.' >&2; exit 1; }
for p in gtk/settings.ini fuzzel/fuzzel.ini waybar/config theme.conf; do
    cp "$S/pre-icons/$p" "$T/$p"
done
TMP=$(mktemp "$ROOT/scripts/.matrix-icons-rollback.XXXXXX"); trap 'rm -f "$TMP"' EXIT
install -m 755 "$B" "$TMP"; mv -f "$TMP" "$D"
LINK="$HOME/.local/share/icons/SwirlDesk-MATRIX"
if [[ -L "$LINK" && $(readlink -f "$LINK") == "$T/icons/SwirlDesk-MATRIX" ]]; then rm "$LINK"; fi
echo 'MATRIX v0.3.1 icon configuration restored. SVG assets remain inert.'
