#!/usr/bin/env bash
set -u
ROOT="$HOME/.config/swirldesk"
DST="$HOME/.local/share/icons/SwirlDesk-FIELD-Plasma"
TRAY_ROOT="$HOME/.local/share/plasma/plasmoids/org.kde.plasma.private.systemtray"
TRAY="$TRAY_ROOT/contents/ui/items/StatusNotifierItem.qml"
TRAY_ICONS="$TRAY_ROOT/contents/icons"
TEMPLATE="$ROOT/plasma/field/tray/StatusNotifierItem.qml"
OK=0; BAD=0; INFO=0
ok(){ printf 'OK      %-36s %s\n' "$1" "${2:-}"; OK=$((OK+1)); }
bad(){ printf 'MISMATCH %-36s %s\n' "$1" "${2:-}"; BAD=$((BAD+1)); }
info(){ printf 'INFO    %-36s %s\n' "$1" "${2:-}"; INFO=$((INFO+1)); }

printf 'FIELD // RECOGNIZABLE MONOCHROME PANEL\n----------------------------------------\n'
THEME="$(kreadconfig6 --file kdeglobals --group Icons --key Theme 2>/dev/null || true)"
[[ "$THEME" == "SwirlDesk-FIELD-Plasma" ]] && ok 'FIELD icon theme active' "$THEME" || bad 'FIELD icon theme active' "${THEME:-<empty>}"

check_alias(){
  local label="$1" file="$2" target="$3"
  if [[ -L "$DST/scalable/apps/$file" && "$(readlink "$DST/scalable/apps/$file")" == "$target" ]]; then
    ok "$label" "$file -> $target"
  elif [[ -f "$DST/scalable/apps/$file" ]]; then
    ok "$label" "$file"
  else
    bad "$label" "missing $file"
  fi
}
check_alias 'Konsole override' utilities-terminal.svg field-terminal.svg
check_alias 'Dolphin override' system-file-manager.svg field-files.svg
check_alias 'Brave override' brave-browser.svg field-browser-b.svg
check_alias 'Firefox override' firefox.svg field-browser-f.svg
check_alias 'Signal override' signal-desktop.svg field-chat.svg
check_alias 'Bitwarden override' bitwarden.svg field-vault.svg
check_alias 'Nextcloud override' Nextcloud.svg field-cloud.svg

if [[ -f "$TRAY" ]]; then
  grep -Fq 'FIELD 0.9.3.7 DIRECT SNI OVERRIDE' "$TRAY" && ok 'tray delegate revision' '0.9.3.7 direct QML installed' || bad 'tray delegate revision' 'direct 0.9.3.7 QML missing'
  grep -Fq 'fieldIdentity' "$TRAY" && grep -Fq 'fieldIsSignal' "$TRAY" && grep -Fq 'fieldIsBitwarden' "$TRAY" && ok 'tray recognizable overrides' 'stable Plasma 6.3.5 SNI identity scan' || bad 'tray recognizable overrides' 'identity binding missing'
  grep -Fq 'Qt.resolvedUrl("../../icons/field-chat.svg")' "$TRAY" && ok 'Signal tray source' 'direct local FIELD vector' || bad 'Signal tray source' 'direct vector binding missing'
  grep -Fq 'Qt.resolvedUrl("../../icons/field-vault.svg")' "$TRAY" && ok 'Bitwarden tray source' 'direct local FIELD vector' || bad 'Bitwarden tray source' 'direct vector binding missing'
  [[ -r "$TRAY_ICONS/field-chat.svg" ]] && ok 'Signal tray vector' "$TRAY_ICONS/field-chat.svg" || bad 'Signal tray vector' 'missing'
  [[ -r "$TRAY_ICONS/field-vault.svg" ]] && ok 'Bitwarden tray vector' "$TRAY_ICONS/field-vault.svg" || bad 'Bitwarden tray vector' 'missing'
  grep -Fq 'isMask: taskIcon.fieldHasOverride' "$TRAY" && ok 'tray icon mask' 'Signal/Bitwarden only' || bad 'tray icon mask' 'missing'
  grep -Fq 'active: !taskIcon.fieldHasOverride && taskIcon.containsMouse' "$TRAY" && ok 'override active-color guard' 'QIcon active mode bypassed for overrides' || bad 'override active-color guard' 'missing'
  grep -Fq '#a68a5b' "$TRAY" && grep -Fq '#d9d3c3' "$TRAY" && ok 'tray FIELD colors' 'Coyote hover/attention, warm off-white normal' || bad 'tray FIELD colors' 'missing'
  if [[ -f "$TEMPLATE" ]]; then
    if cmp -s "$TEMPLATE" "$TRAY"; then
      ok 'tray delegate integrity' 'installed delegate matches FIELD template byte-for-byte'
    else
      bad 'tray delegate integrity' 'installed delegate differs from FIELD template'
    fi
  else
    bad 'tray delegate template' 'missing from ~/.config/swirldesk'
  fi
else
  bad 'system tray FIELD override' 'not installed'
fi

if systemctl --user is-active plasma-plasmashell.service >/dev/null 2>&1 || pgrep -x plasmashell >/dev/null 2>&1; then
  ok 'Plasma shell' 'running'
else
  bad 'Plasma shell' 'not running'
fi

info 'tray behavior' '0.9.3.7 installs the patched Plasma 6.3.5 delegate directly; no in-place QML patching'
printf '\nFIELD // PANEL ICON DOCTOR: %d OK / %d issue(s) / %d info\n' "$OK" "$BAD" "$INFO"
[[ "$BAD" -eq 0 ]]
