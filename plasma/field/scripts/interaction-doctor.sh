#!/usr/bin/env bash
set -u
ok=0; fail=0; info=0
ok(){ printf 'OK      %-38s %s\n' "$1" "${2:-}"; ((ok+=1)); }
warn(){ printf 'MISMATCH %-35s %s\n' "$1" "${2:-}"; ((fail+=1)); }
inf(){ printf 'INFO    %-38s %s\n' "$1" "${2:-}"; ((info+=1)); }
kr(){ kreadconfig6 --file "$1" --group "$2" --key "$3" 2>/dev/null || true; }
has_any(){ grep -Fq -- "$1" "$HOME/.config/kglobalshortcutsrc" 2>/dev/null; }

[[ "$(kr kwinrc Desktops Number)" == *6* ]] && ok 'workspace count' 6 || warn 'workspace count' "$(kr kwinrc Desktops Number) (want 6)"
[[ "$(kr kwinrc Desktops Rows)" == *1* ]] && ok 'workspace rows' 1 || warn 'workspace rows' "$(kr kwinrc Desktops Rows) (want 1)"
for n in 1 6; do
  a="$(kr kglobalshortcutsrc kwin "Switch to Desktop $n")"
  [[ "$a" == *"Meta+$n"* ]] && ok "Meta+$n -> desktop $n" "$a" || warn "Meta+$n -> desktop $n" "$a"
done

for spec in \
 'org.swirldesk.field.konsole.desktop|Meta+Return|FIELD // Terminal' \
 'org.swirldesk.field.dolphin.desktop|Meta+E|FIELD // Files' \
 'org.swirldesk.field.firefox.desktop|Meta+B|FIELD // Browser' \
 'org.swirldesk.field.applauncher.desktop|Meta+Ctrl+Return|FIELD // Quick Launch'; do
 IFS='|' read -r file key label <<<"$spec"
 app="$HOME/.local/share/applications/$file"
 [[ -f "$app" ]] && ok "$label desktop" "$app" || warn "$label desktop" missing
 has_any "$key" && ok "$label shortcut" "$key" || inf "$label shortcut" 'not persisted; test live'
done


LAUNCHER_HELPER="$HOME/.config/swirldesk/plasma/field/scripts/plasma-launcher.sh"
LAUNCHER_CFG="$HOME/.config/swirldesk/plasma/field/fuzzel/fuzzel.ini"
[[ -x "$LAUNCHER_HELPER" ]] && ok 'FIELD quick-launch helper' "$LAUNCHER_HELPER" || warn 'FIELD quick-launch helper' 'missing/not executable'
[[ -r "$LAUNCHER_CFG" ]] && ok 'FIELD Fuzzel config' "$LAUNCHER_CFG" || warn 'FIELD Fuzzel config' 'missing'
if command -v fuzzel >/dev/null 2>&1; then
  ok 'Fuzzel executable' "$(command -v fuzzel)"
else
  inf 'Fuzzel executable' 'missing; Meta+Ctrl+Return falls back to KRunner'
fi

MOVE_LOADER="$HOME/.config/swirldesk/plasma/field/scripts/field-workspaces-load.sh"
MOVE_SCRIPT="$HOME/.config/swirldesk/plasma/field/scripts/field-workspaces-de.js"
MOVE_AUTOSTART="$HOME/.config/autostart/org.swirldesk.field.kwin-workspaces.desktop"
[[ -x "$MOVE_LOADER" ]] && ok 'FIELD workspace loader' "$MOVE_LOADER" || warn 'FIELD workspace loader' 'missing/not executable'
[[ -r "$MOVE_SCRIPT" ]] && ok 'FIELD workspace KWin script' "$MOVE_SCRIPT" || warn 'FIELD workspace KWin script' 'missing'
[[ -f "$MOVE_AUTOSTART" ]] && ok 'FIELD workspace autostart' "$MOVE_AUTOSTART" || warn 'FIELD workspace autostart' 'missing'

QDBUS=''
for c in qdbus6 qdbus-qt6 qdbus; do
  if command -v "$c" >/dev/null 2>&1; then QDBUS="$c"; break; fi
done
[[ -n "$QDBUS" ]] && ok 'KWin D-Bus client' "$QDBUS" || warn 'KWin D-Bus client' 'qdbus6/qdbus-qt6 missing'
if command -v gdbus >/dev/null 2>&1; then
  ok 'KGlobalAccel live editor' "$(command -v gdbus)"
else
  warn 'KGlobalAccel live editor' 'gdbus missing; live PowerDevil Meta+B release unavailable'
fi

if [[ -r "$MOVE_SCRIPT" ]]; then
  for key in 'Meta+!' 'Meta+"' 'Meta+§' 'Meta+$' 'Meta+%' 'Meta+&'; do
    grep -Fq "$key" "$MOVE_SCRIPT" || { warn 'German move+follow mapping' "missing $key"; key=''; break; }
  done
  [[ -n "${key:-}" ]] && ok 'German move+follow mapping' 'Meta+Shift+1..6 -> ! " § $ % &'
fi

# The script should remain loaded for the entire live Plasma session. Query it
# when possible, but do not turn a missing live session into a false config error.
if [[ -n "$QDBUS" ]] && (pgrep -x kwin_wayland >/dev/null 2>&1 || pgrep -x kwin_x11 >/dev/null 2>&1); then
  live="$($QDBUS org.kde.KWin /Scripting org.kde.kwin.Scripting.isScriptLoaded swirldesk-field-workspaces-de 2>/dev/null || true)"
  if [[ "$live" == 'true' || "$live" == '1' ]]; then
    ok 'FIELD workspace engine live' "$live"
  else
    warn 'FIELD workspace engine live' "${live:-not loaded}"
  fi
else
  inf 'FIELD workspace engine live' 'not checked outside an active KWin session'
fi

legacy=0
for n in 1 2 3 4 5 6; do
  [[ -e "$HOME/.local/share/applications/org.swirldesk.field.movefollow${n}.desktop" ]] && legacy=1
  [[ -e "$HOME/.local/share/kglobalaccel/org.swirldesk.field.movefollow${n}.desktop" ]] && legacy=1
done
[[ "$legacy" -eq 0 ]] && ok 'legacy move+follow launchers' 'removed' || warn 'legacy move+follow launchers' 'still present'
inf 'move+follow engine' 'persistent KWin registerShortcut() with German-layout keysyms'

# 0.9.3.6: verify the freshly re-registered keysyms and the specific stale
# test action that previously stole Meta+Shift+2 (Meta+").
expected=('Meta+!' 'Meta+"' 'Meta+§' 'Meta+$' 'Meta+%' 'Meta+&')
for idx in 0 1 2 3 4 5; do
  n=$((idx + 1))
  value="$(kr kglobalshortcutsrc kwin "FIELD DE MoveFollow Desktop $n")"
  if [[ "$value" == "${expected[$idx]}"* ]]; then
    ok "Meta+Shift+$n move+follow config" "${expected[$idx]}"
  else
    warn "Meta+Shift+$n move+follow config" "${value:-<empty>} (want ${expected[$idx]})"
  fi
done
stale_de="$(kr kglobalshortcutsrc kwin 'FIELD MoveFollow DE Test')"
[[ "$stale_de" != *'Meta+"'* ]] && ok 'stale DE test shortcut' 'released' || warn 'stale DE test shortcut' "$stale_de"

# Meta+B belongs exclusively to FIELD Browser. Parse the INI by component so a
# second owner such as PowerDevil is reported instead of being hidden by the
# browser entry itself.
KGS="$HOME/.config/kglobalshortcutsrc"
if [[ -r "$KGS" ]]; then
  conflicts="$(awk '
    /^\[/ { g=$0; sub(/^\[/,"",g); sub(/\]$/,"",g); next }
    /Meta\+B/ && g != "org.swirldesk.field.firefox.desktop" { print g ":" $0 }
  ' "$KGS")"
  if [[ -z "$conflicts" ]]; then
    ok 'Meta+B conflict scan' 'free for FIELD // Browser'
  else
    warn 'Meta+B conflict scan' "$conflicts"
  fi
fi

if command -v spectacle >/dev/null 2>&1; then
  ok 'Spectacle executable' "$(command -v spectacle)"
  spectacle --version 2>/dev/null | head -n1 | xargs -r printf 'INFO    %-38s %s\n' 'Spectacle version'
  for spec in \
   'org.swirldesk.field.screenshot.area.desktop|Print|FIELD // Capture Area' \
   'org.swirldesk.field.screenshot.window.desktop|Meta+Print|FIELD // Capture Window' \
   'org.swirldesk.field.screenshot.screen.desktop|Ctrl+Print|FIELD // Capture Screen'; do
    IFS='|' read -r file key label <<<"$spec"
    [[ -f "$HOME/.local/share/applications/$file" ]] && ok "$label launcher" "$key" || warn "$label launcher" missing
  done
else
  warn 'Spectacle executable' 'MISSING — sudo apt install kde-spectacle'
fi

[[ -f "$HOME/.local/share/applications/org.swirldesk.field.power.desktop" ]] && ok 'FIELD // Power desktop' installed || warn 'FIELD // Power desktop' missing

printf '\nFIELD // INTERACTION DOCTOR: %d OK / %d issue(s) / %d info\n' "$ok" "$fail" "$info"
(( fail == 0 ))
