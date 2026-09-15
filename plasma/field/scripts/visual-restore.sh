#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
STATE="$ROOT/state"

layout="$(cat "$STATE/plasma_field_visual_prev_layout" 2>/dev/null || echo thumbnail_grid)"
outline="$(cat "$STATE/plasma_field_visual_prev_outline" 2>/dev/null || echo true)"
highlight="$(cat "$STATE/plasma_field_visual_prev_highlight" 2>/dev/null || echo true)"

kwriteconfig6 --file kwinrc --group TabBox --key LayoutName "$layout"
kwriteconfig6 --file kwinrc --group TabBox --key ShowOutline "$outline"
kwriteconfig6 --file kwinrc --group TabBox --key HighlightWindows "$highlight"

QDBUS=''
for c in qdbus6 qdbus-qt6 qdbus; do
  if command -v "$c" >/dev/null 2>&1; then QDBUS="$c"; break; fi
done

if [[ -n "$QDBUS" ]] && (pgrep -x kwin_wayland >/dev/null 2>&1 || pgrep -x kwin_x11 >/dev/null 2>&1); then
  "$QDBUS" org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
fi

if [[ -n "$QDBUS" ]] && pgrep -x plasmashell >/dev/null 2>&1; then
  "$QDBUS" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
    panels().forEach((p) => {
        var field = p.widgets("org.swirldesk.fieldpager");
        if (field.length > 0) {
            var pos = field[0].index;
            field[0].remove();
            var stock = p.widgets("org.kde.plasma.pager");
            if (stock.length === 0) {
                var nw = p.addWidget("org.kde.plasma.pager");
                nw.index = pos;
            }
        }
    });
  ' >/dev/null 2>&1 || true
fi

echo "FIELD // visual layer restored: pager=Plasma, Alt+Tab=$layout"
