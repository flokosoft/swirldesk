#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
FIELD="$ROOT/plasma/field"
command -v kwriteconfig6 >/dev/null 2>&1 || { echo 'kwriteconfig6 not found.' >&2; exit 1; }
"$FIELD/scripts/window-backup.sh"

# Breeze stays the compatibility-first decoration engine; FIELD makes it compact.
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.breeze
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme Breeze
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key BorderSize Tiny
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key BorderSizeAuto false
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft ''
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight IAX

# Dry / field-workstation behavior: no decorative compositor effects.
for key in blur wobblywindows translucency magiclamp; do
  kwriteconfig6 --file kwinrc --group Plugins --key "${key}Enabled" false
done
kwriteconfig6 --file kwinrc --group Windows --key FocusPolicy ClickToFocus
kwriteconfig6 --file kwinrc --group Windows --key Placement Smart
kwriteconfig6 --file kwinrc --group Windows --key TitlebarDoubleClickCommand Maximize
kwriteconfig6 --file kwinrc --group Windows --key WindowSnapZone 10
kwriteconfig6 --file kwinrc --group Windows --key BorderSnapZone 10

# Keep the widget/application style on Breeze and let FIELD colors do the identity work.
kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle Breeze

QDBUS=''
for c in qdbus6 qdbus qdbus-qt6; do
  command -v "$c" >/dev/null 2>&1 && { QDBUS="$c"; break; }
done
if [[ -n "$QDBUS" ]] && pgrep -x kwin_wayland >/dev/null 2>&1; then
  "$QDBUS" org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
fi

echo 'FIELD // PLASMA WINDOW LAYER APPLIED'
echo '  decoration  Breeze / FIELD colors'
echo '  border      Tiny'
echo '  buttons     minimize | maximize | close'
echo '  effects     blur / wobble / translucency / magic-lamp OFF'
echo '  behavior    click-to-focus / smart placement'
