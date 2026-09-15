#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
FIELD="$ROOT/plasma/field"

command -v kwriteconfig6 >/dev/null 2>&1 || { echo 'kwriteconfig6 not found.' >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo 'python3 not found.' >&2; exit 1; }
command -v dolphin >/dev/null 2>&1 || { echo 'Dolphin is not installed.' >&2; exit 1; }

"$FIELD/scripts/dolphin-backup.sh"

# --- FIELD behaviour / density ------------------------------------------------
# Keep the useful KDE file-manager features, but remove visual noise and make
# the default view read like a compact field workstation.
kwriteconfig6 --file dolphinrc --group General --key EditableUrl false
kwriteconfig6 --file dolphinrc --group General --key ShowFullPath true
kwriteconfig6 --file dolphinrc --group General --key ShowFullPathInTitlebar false
kwriteconfig6 --file dolphinrc --group General --key AlwaysShowTabBar false
kwriteconfig6 --file dolphinrc --group General --key ShowCloseButtonOnTabs true
kwriteconfig6 --file dolphinrc --group General --key RememberOpenedTabs true
kwriteconfig6 --file dolphinrc --group General --key GlobalViewProps true
kwriteconfig6 --file dolphinrc --group General --key BrowseThroughArchives true
kwriteconfig6 --file dolphinrc --group General --key ShowToolTips false
kwriteconfig6 --file dolphinrc --group General --key ShowSelectionToggle false
kwriteconfig6 --file dolphinrc --group General --key ShowStatusBar Small
kwriteconfig6 --file dolphinrc --group General --key ShowZoomSlider false
kwriteconfig6 --file dolphinrc --group General --key LockPanels true
kwriteconfig6 --file dolphinrc --group General --key DynamicView false

# Compact Details view. These keys are from Dolphin's KF6 KConfig schemas.
kwriteconfig6 --file dolphinrc --group DetailsMode --key UseSystemFont true
kwriteconfig6 --file dolphinrc --group DetailsMode --key IconSize 22
kwriteconfig6 --file dolphinrc --group DetailsMode --key PreviewSize 32
kwriteconfig6 --file dolphinrc --group DetailsMode --key LeftPadding 8
kwriteconfig6 --file dolphinrc --group DetailsMode --key RightPadding 8
kwriteconfig6 --file dolphinrc --group DetailsMode --key HighlightEntireRow true
kwriteconfig6 --file dolphinrc --group DetailsMode --key ExpandableFolders true

# If the user switches to icons, keep that mode restrained too.
kwriteconfig6 --file dolphinrc --group IconsMode --key UseSystemFont true
kwriteconfig6 --file dolphinrc --group IconsMode --key IconSize 48
kwriteconfig6 --file dolphinrc --group IconsMode --key PreviewSize 64
kwriteconfig6 --file dolphinrc --group IconsMode --key MaximumTextLines 2

# Technical/operational display: actual timestamps instead of "Yesterday".
kwriteconfig6 --file dolphinrc --group ContentDisplay --key UseShortRelativeDates false
kwriteconfig6 --file dolphinrc --group ContentDisplay --key DirectorySizeMode ContentCount

# Places/sidebar density used by Dolphin's Places panel on Debian/KDE.
kwriteconfig6 --file dolphinrc --group 'KFileDialog Settings' --key 'Places Icons Auto-resize' false
kwriteconfig6 --file dolphinrc --group 'KFileDialog Settings' --key 'Places Icons Static Size' 22

# Keep the chrome dry and predictable.
kwriteconfig6 --file dolphinrc --group MainWindow --key MenuBar Disabled
kwriteconfig6 --file dolphinrc --group MainWindow --key ToolBarsMovable Disabled
mkdir -p "$HOME/.local/state"
kwriteconfig6 --file "$HOME/.local/state/dolphinstaterc" --group MainWindow --key ToolBarsMovable Disabled
kwriteconfig6 --file dolphinrc --group 'MainWindow Toolbar mainToolBar' --key ToolButtonStyle IconOnly

# --- Default global view -------------------------------------------------------
# Dolphin 24.12+ stores this as user.kde.fm.viewproperties#1 on
# ~/.local/share/dolphin/view_properties/global. Use Python so no attr package is
# required. If xattrs are unavailable, create Dolphin's legacy .directory
# fallback instead.
GLOBAL="$HOME/.local/share/dolphin/view_properties/global"
mkdir -p "$GLOBAL"
if python3 - "$GLOBAL" <<'PY'
import datetime, os, pathlib, sys
path = pathlib.Path(sys.argv[1])
now = datetime.datetime.now()
stamp = f"{now.year},{now.month},{now.day},{now.hour},{now.minute},{now.second}.{now.microsecond//1000:03d}"
payload = (
    "[Dolphin]\n"
    "PreviewsShown=true\n"
    "SortFoldersFirst=true\n"
    "SortHiddenLast=true\n"
    f"Timestamp={stamp}\n"
    "Version=4\n"
    "ViewMode=1\n"
    "\n[Settings]\n"
    "HiddenFilesShown=false\n"
).encode("utf-8")
try:
    os.setxattr(path, b"user.kde.fm.viewproperties#1", payload)
except OSError as exc:
    print(f"FIELD_XATTR_FAILED:{exc}")
    raise SystemExit(3)
print("FIELD_XATTR_OK")
PY
then
  rm -f -- "$GLOBAL/.directory"
  VIEWSTORE='xattr'
else
  cat > "$GLOBAL/.directory" <<'EOF2'
[Dolphin]
PreviewsShown=true
SortFoldersFirst=true
SortHiddenLast=true
Version=4
ViewMode=1

[Settings]
HiddenFilesShown=false
EOF2
  VIEWSTORE='.directory fallback'
fi

# --- Reduced toolbar -----------------------------------------------------------
# KXmlGui still uses the kxmlgui5 user location for Dolphin on Plasma 6. Rather
# than ship a version-specific full dolphinui.rc, derive it from the user's own
# file or the system file and replace only mainToolBar. This preserves the exact
# menu/action schema supplied by the installed Dolphin version.
UI_DST="$HOME/.local/share/kxmlgui5/dolphin/dolphinui.rc"
UI_SRC=''
for candidate in \
  "$UI_DST" \
  /usr/share/kxmlgui5/dolphin/dolphinui.rc \
  /usr/share/kxmlgui6/dolphin/dolphinui.rc; do
  if [[ -f "$candidate" ]]; then UI_SRC="$candidate"; break; fi
done

# Debian 13 Dolphin 25.04.3 embeds the stock dolphinui.rc in the application
# rather than shipping it as a standalone file. 0.9.3 therefore found no
# patch source on a clean profile. Fall back to a FIELD copy derived from the
# exact upstream v25.04.3 dolphinui.rc in that case.
if [[ -z "$UI_SRC" ]]; then
  DOLPHIN_VER="$(dolphin --version 2>/dev/null | awk 'NR==1 {print $2}' || true)"
  TEMPLATE="$FIELD/dolphin/dolphinui-25.04.3.rc"
  if [[ "$DOLPHIN_VER" == 25.04.* && -f "$TEMPLATE" ]]; then
    mkdir -p "$(dirname "$UI_DST")"
    cp -a -- "$TEMPLATE" "$UI_DST"
    UI_SRC="$UI_DST"
    TOOLBAR_STATUS='FIELD reduced toolbar installed (Debian 13 template)'
  fi
fi

TOOLBAR_STATUS="${TOOLBAR_STATUS:-not changed (no compatible toolbar XML source)}"
if [[ -n "$UI_SRC" ]]; then
  mkdir -p "$(dirname "$UI_DST")"
  TMP="$(mktemp)"
  cp -a -- "$UI_SRC" "$TMP"
  if python3 - "$TMP" "$UI_DST" <<'PY'
import pathlib, sys, xml.etree.ElementTree as ET
src = pathlib.Path(sys.argv[1])
dst = pathlib.Path(sys.argv[2])
parser = ET.XMLParser(target=ET.TreeBuilder(insert_comments=True))
tree = ET.parse(src, parser=parser)
root = tree.getroot()
tb = None
for el in root.iter():
    if el.tag.endswith('ToolBar') and el.attrib.get('name') == 'mainToolBar':
        tb = el
        break
if tb is None:
    raise SystemExit('mainToolBar not found')
# Preserve attributes/text node, replace only children.
for child in list(tb):
    tb.remove(child)
text = ET.SubElement(tb, 'text', {'context': '@title:menu'})
text.text = 'FIELD // FILES'
for action in ('go_back','go_forward','go_up'):
    ET.SubElement(tb, 'Action', {'name': action})
ET.SubElement(tb, 'Separator', {'name': 'field_nav'})
ET.SubElement(tb, 'Action', {'name': 'url_navigators'})
ET.SubElement(tb, 'Separator', {'name': 'field_view'})
for action in ('details','show_preview','split_view','toggle_search','hamburger_menu'):
    ET.SubElement(tb, 'Action', {'name': action})
ET.indent(tree, space='    ')
dst.parent.mkdir(parents=True, exist_ok=True)
tree.write(dst, encoding='utf-8', xml_declaration=True)
PY
  then
    if [[ "$TOOLBAR_STATUS" != *'Debian 13 template'* ]]; then
      TOOLBAR_STATUS='FIELD reduced toolbar installed'
    fi
  else
    echo 'WARNING: could not patch Dolphin toolbar; other FIELD Dolphin settings were applied.' >&2
    TOOLBAR_STATUS='not changed (XML patch failed)'
  fi
  rm -f -- "$TMP"
fi

command -v kbuildsycoca6 >/dev/null 2>&1 && kbuildsycoca6 --noincremental >/dev/null 2>&1 || true

cat <<TXT

FIELD // DOLPHIN 0.9.3 APPLIED

  VIEW
    default            Details
    row highlight      full
    row padding        8 px
    details icons      22 px
    previews           enabled / 32 px
    folders first      yes
    hidden last        yes
    timestamps         absolute
    global store       $VIEWSTORE

  CHROME
    full path          yes
    menubar            hidden
    statusbar          small
    zoom slider        hidden
    sidebar icons      22 px
    toolbar            $TOOLBAR_STATUS

  FIELD colors/icons are inherited from the already active
  SwirlDesk FIELD Plasma color scheme and icon overlay.

Close all Dolphin windows once and reopen Dolphin to load the new KXmlGui toolbar.
No Plasma logout is required.
TXT
