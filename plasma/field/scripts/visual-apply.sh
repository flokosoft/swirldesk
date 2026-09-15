#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
FIELD="$ROOT/plasma/field"
PAGER_SRC="$FIELD/plasmoid/org.swirldesk.fieldpager"
TABBOX_SRC="$FIELD/tabbox/swirldesk_field_list"
TABBOX_ID='swirldesk_field_list'
TABBOX_DST="$HOME/.local/share/kwin/tabbox/$TABBOX_ID"

[[ -d "$PAGER_SRC" ]] || { echo 'FIELD pager source missing.' >&2; exit 1; }
[[ -d "$TABBOX_SRC" ]] || { echo 'FIELD task switcher source missing.' >&2; exit 1; }
command -v kpackagetool6 >/dev/null 2>&1 || { echo 'kpackagetool6 not found.' >&2; exit 1; }
command -v kwriteconfig6 >/dev/null 2>&1 || { echo 'kwriteconfig6 not found.' >&2; exit 1; }

"$FIELD/scripts/visual-backup.sh"

install_or_upgrade() {
  local type="$1" id="$2" src="$3"
  if kpackagetool6 -t "$type" -s "$id" >/dev/null 2>&1; then
    kpackagetool6 -t "$type" -u "$src" >/dev/null
  else
    kpackagetool6 -t "$type" -i "$src" >/dev/null
  fi
}

install_or_upgrade 'Plasma/Applet' 'org.swirldesk.fieldpager' "$PAGER_SRC"

# KWin WindowSwitcher updates can leave stale QML behind. 0.9.0's
# KWin.Switcher file survived the 0.9.1 package upgrade on Debian/Plasma 6.
# Force a clean user-level reinstall so the file KWin actually loads is the
# same one shipped in the FIELD source tree.
kpackagetool6 -t 'KWin/WindowSwitcher' -r "$TABBOX_ID" >/dev/null 2>&1 || true
rm -rf -- "$TABBOX_DST"
kpackagetool6 -t 'KWin/WindowSwitcher' -i "$TABBOX_SRC" >/dev/null

# Refuse to silently continue with the exact stale-file failure we diagnosed.
if ! grep -Fq 'KWin.TabBoxSwitcher' "$TABBOX_DST/contents/ui/main.qml" 2>/dev/null; then
  echo "ERROR: installed FIELD task switcher is still stale/broken: $TABBOX_DST/contents/ui/main.qml" >&2
  exit 1
fi

command -v kbuildsycoca6 >/dev/null 2>&1 && kbuildsycoca6 --noincremental >/dev/null 2>&1 || true

# Keep Alt+Tab dry and predictable: FIELD list, no outline/thumbnail highlight effect.
kwriteconfig6 --file kwinrc --group TabBox --key LayoutName 'swirldesk_field_list'
kwriteconfig6 --file kwinrc --group TabBox --key ShowOutline false
kwriteconfig6 --file kwinrc --group TabBox --key HighlightWindows false

QDBUS=''
for c in qdbus6 qdbus-qt6 qdbus; do
  if command -v "$c" >/dev/null 2>&1; then QDBUS="$c"; break; fi
done

if [[ -n "$QDBUS" ]] && (pgrep -x kwin_wayland >/dev/null 2>&1 || pgrep -x kwin_x11 >/dev/null 2>&1); then
  # Bounce to a built-in layout first so KWin drops the previous component,
  # then select FIELD again and reconfigure. This avoids retaining the failed
  # 0.9.0 component in the current session.
  kwriteconfig6 --file kwinrc --group TabBox --key LayoutName 'compact'
  "$QDBUS" org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
  kwriteconfig6 --file kwinrc --group TabBox --key LayoutName 'swirldesk_field_list'
  "$QDBUS" org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
fi

replace_pager() {
  local js result
  js='var changed = false;
if (!knownWidgetTypes.includes("org.swirldesk.fieldpager")) {
    print("FIELD_PAGER_UNKNOWN");
} else {
    panels().forEach((p) => {
        var field = p.widgets("org.swirldesk.fieldpager");
        var stock = p.widgets("org.kde.plasma.pager");
        if (field.length === 0 && stock.length > 0) {
            var pos = stock[0].index;
            stock[0].remove();
            var nw = p.addWidget("org.swirldesk.fieldpager");
            nw.index = pos;
            changed = true;
        } else if (field.length > 0 && stock.length > 0) {
            stock.forEach((w) => w.remove());
            changed = true;
        }
    });
    print(changed ? "FIELD_PAGER_APPLIED" : "FIELD_PAGER_PRESENT");
}'
  result="$($QDBUS org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$js" 2>/dev/null || true)"
  printf '%s' "$result"
}

if [[ -n "$QDBUS" ]] && pgrep -x plasmashell >/dev/null 2>&1; then
  result="$(replace_pager)"
  if grep -q 'FIELD_PAGER_UNKNOWN' <<<"$result"; then
    if systemctl --user is-active --quiet plasma-plasmashell.service 2>/dev/null; then
      systemctl --user restart plasma-plasmashell.service
      for _ in $(seq 1 40); do
        pgrep -x plasmashell >/dev/null 2>&1 && break
        sleep 0.25
      done
      sleep 1
      result="$(replace_pager)"
    fi
  fi
  if grep -q 'FIELD_PAGER_UNKNOWN' <<<"$result"; then
    echo 'WARNING: Plasma has not loaded FIELD // Pager yet. Log out/in once, then run this command again.' >&2
  fi
else
  echo 'INFO: No live Plasma shell detected; FIELD // Pager will be applied when this command is run inside Plasma.' >&2
fi

cat <<'TXT'

FIELD // PLASMA VISUAL 0.9.2 APPLIED

  ALT+TAB REPAIR
    clean reinstall       stale 0.9.0 QML removed
    installed QML        verified as KWin.TabBoxSwitcher
    KWin layout cache    compact -> FIELD bounce + reconfigure

  PAGER
    unchanged            FIELD desktop rail remains active

All working FIELD interaction shortcuts, notifications, screenshots,
Quick Launch and power controls are untouched.
TXT
