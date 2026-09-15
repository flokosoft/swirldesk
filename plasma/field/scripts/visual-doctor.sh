#!/usr/bin/env bash
set -u
ROOT="$HOME/.config/swirldesk"
FIELD="$ROOT/plasma/field"
ok=0; fail=0; info=0
ok(){ printf 'OK      %-38s %s\n' "$1" "${2:-}"; ((ok+=1)); }
warn(){ printf 'MISMATCH %-35s %s\n' "$1" "${2:-}"; ((fail+=1)); }
inf(){ printf 'INFO    %-38s %s\n' "$1" "${2:-}"; ((info+=1)); }

PAGER_SRC="$FIELD/plasmoid/org.swirldesk.fieldpager"
TABBOX_SRC="$FIELD/tabbox/swirldesk_field_list"
TABBOX_DST="$HOME/.local/share/kwin/tabbox/swirldesk_field_list"
[[ -r "$PAGER_SRC/metadata.json" && -r "$PAGER_SRC/contents/ui/main.qml" ]] && ok 'FIELD pager source' "$PAGER_SRC" || warn 'FIELD pager source' missing
[[ -r "$TABBOX_SRC/metadata.json" && -r "$TABBOX_SRC/contents/ui/main.qml" ]] && ok 'FIELD task switcher source' "$TABBOX_SRC" || warn 'FIELD task switcher source' missing
if grep -Fq 'import org.kde.kwin 3.0 as KWin' "$TABBOX_SRC/contents/ui/main.qml" 2>/dev/null && grep -Fq 'KWin.TabBoxSwitcher' "$TABBOX_SRC/contents/ui/main.qml" 2>/dev/null && grep -Fq 'PlasmaCore.Dialog' "$TABBOX_SRC/contents/ui/main.qml" 2>/dev/null; then
  ok 'FIELD task switcher source API' 'KWin 3.0 + TabBoxSwitcher + Dialog'
else
  warn 'FIELD task switcher source API' 'outdated/broken QML API'
fi

if command -v kpackagetool6 >/dev/null 2>&1; then
  kpackagetool6 -t Plasma/Applet -s org.swirldesk.fieldpager >/dev/null 2>&1 && ok 'FIELD pager package' installed || warn 'FIELD pager package' 'not installed'
  kpackagetool6 -t KWin/WindowSwitcher -s swirldesk_field_list >/dev/null 2>&1 && ok 'FIELD task switcher package' installed || warn 'FIELD task switcher package' 'not installed'
else
  warn 'kpackagetool6' missing
fi

# Crucial 0.9.2 check: inspect what KWin loads, not merely our source tree.
if [[ -r "$TABBOX_DST/contents/ui/main.qml" ]]; then
  if grep -Fq 'import org.kde.kwin 3.0 as KWin' "$TABBOX_DST/contents/ui/main.qml" && grep -Fq 'KWin.TabBoxSwitcher' "$TABBOX_DST/contents/ui/main.qml" && ! grep -Eq 'KWin\.Switcher[[:space:]]*\{' "$TABBOX_DST/contents/ui/main.qml"; then
    ok 'installed Alt+Tab QML' 'fresh KWin 3.0 FIELD component'
  else
    warn 'installed Alt+Tab QML' 'STALE: old KWin.Switcher component still installed'
  fi
  if cmp -s "$TABBOX_SRC/contents/ui/main.qml" "$TABBOX_DST/contents/ui/main.qml"; then
    ok 'Alt+Tab source/install match' identical
  else
    warn 'Alt+Tab source/install match' 'installed file differs from FIELD source'
  fi
else
  warn 'installed Alt+Tab QML' missing
fi

if command -v kreadconfig6 >/dev/null 2>&1; then
  layout="$(kreadconfig6 --file kwinrc --group TabBox --key LayoutName 2>/dev/null || true)"
  [[ "$layout" == 'swirldesk_field_list' ]] && ok 'Alt+Tab layout' "$layout" || warn 'Alt+Tab layout' "${layout:-unset}"
  outline="$(kreadconfig6 --file kwinrc --group TabBox --key ShowOutline 2>/dev/null || true)"
  [[ "$outline" == 'false' ]] && ok 'Alt+Tab outline' disabled || inf 'Alt+Tab outline' "${outline:-default}"
else
  warn 'kreadconfig6' missing
fi

APPLETS="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
QDBUS=''
for c in qdbus6 qdbus-qt6 qdbus; do
  if command -v "$c" >/dev/null 2>&1; then QDBUS="$c"; break; fi
done

field_live=''
stock_live=''
if [[ -n "$QDBUS" ]] && pgrep -x plasmashell >/dev/null 2>&1; then
  counts="$($QDBUS org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
    var f = 0; var s = 0;
    panels().forEach((p) => {
      f += p.widgets("org.swirldesk.fieldpager").length;
      s += p.widgets("org.kde.plasma.pager").length;
    });
    print("FIELD=" + f + ";STOCK=" + s);
  ' 2>/dev/null || true)"
  field_live="$(sed -n 's/.*FIELD=\([0-9][0-9]*\).*/\1/p' <<<"$counts" | tail -n1)"
  stock_live="$(sed -n 's/.*STOCK=\([0-9][0-9]*\).*/\1/p' <<<"$counts" | tail -n1)"
fi

if [[ -n "$field_live" ]]; then
  [[ "$field_live" -ge 1 ]] && ok 'FIELD pager in panel' "live count $field_live" || warn 'FIELD pager in panel' 'live count 0'
  [[ "${stock_live:-0}" -eq 0 ]] && ok 'stock Plasma pager' removed || inf 'stock Plasma pager' "live count $stock_live"
else
  if grep -Fq 'plugin=org.swirldesk.fieldpager' "$APPLETS" 2>/dev/null; then
    ok 'FIELD pager in panel' persisted
  else
    warn 'FIELD pager in panel' 'not found'
  fi
  if grep -Fq 'plugin=org.kde.plasma.pager' "$APPLETS" 2>/dev/null; then
    inf 'stock Plasma pager' 'still present somewhere'
  else
    ok 'stock Plasma pager' removed
  fi
fi

if pgrep -x plasmashell >/dev/null 2>&1; then ok 'Plasma shell' running; else inf 'Plasma shell' 'not running'; fi
if pgrep -x kwin_wayland >/dev/null 2>&1 || pgrep -x kwin_x11 >/dev/null 2>&1; then ok 'KWin session' running; else inf 'KWin session' 'not running'; fi

printf '\nFIELD // VISUAL DOCTOR: %d OK / %d issue(s) / %d info\n' "$ok" "$fail" "$info"
(( fail == 0 ))
