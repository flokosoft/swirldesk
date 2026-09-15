#!/usr/bin/env bash
set -u
ROOT="$HOME/.config/swirldesk"
FIELD="$ROOT/plasma/field"
rc=0
ok(){ printf 'OK      %s\n' "$1"; }
miss(){ printf 'MISSING %s\n' "$1"; rc=1; }
warn(){ printf 'WARN    %s\n' "$1"; }
[[ -f "$FIELD/panel/layout.js" ]] && ok 'panel/layout.js' || miss 'panel/layout.js'
pgrep -x plasmashell >/dev/null 2>&1 && ok 'plasmashell running' || miss 'plasmashell running'
if command -v qdbus6 >/dev/null 2>&1 || command -v qdbus >/dev/null 2>&1 || command -v qdbus-qt6 >/dev/null 2>&1; then ok 'qdbus client'; else miss 'qdbus client'; fi
for w in org.swirldesk.fieldlabel org.kde.plasma.kickoff org.swirldesk.fieldpager org.kde.plasma.icontasks org.kde.plasma.panelspacer org.kde.plasma.systemtray org.kde.plasma.digitalclock; do
  if [[ -d "/usr/share/plasma/plasmoids/$w" || -d "$HOME/.local/share/plasma/plasmoids/$w" ]] || kpackagetool6 -t Plasma/Applet -s "$w" >/dev/null 2>&1; then ok "$w"; else miss "$w"; fi
done
if systemctl --user is-active --quiet waybar.service 2>/dev/null; then
  warn 'waybar.service is active and may overlap the Plasma rail'
fi
exit "$rc"
