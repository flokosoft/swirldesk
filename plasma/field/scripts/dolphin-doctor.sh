#!/usr/bin/env bash
set -u
ok=0; fail=0; info=0
kr(){ kreadconfig6 --file dolphinrc --group "$1" --key "$2" 2>/dev/null || true; }
ks(){ kreadconfig6 --file "$HOME/.local/state/dolphinstaterc" --group "$1" --key "$2" 2>/dev/null || true; }
check(){
  local label="$1" actual="$2" expected="$3"
  if [[ "$actual" == "$expected" ]]; then
    printf 'OK      %-36s %s\n' "$label" "$actual"; ((ok+=1))
  else
    printf 'MISMATCH %-33s %s (want %s)\n' "$label" "${actual:-<empty>}" "$expected"; ((fail+=1))
  fi
}
check_file(){
  local label="$1" path="$2"
  if [[ -f "$path" ]]; then printf 'OK      %-36s %s\n' "$label" "$path"; ((ok+=1));
  else printf 'MISMATCH %-33s missing: %s\n' "$label" "$path"; ((fail+=1)); fi
}

printf 'FIELD // DOLPHIN\n----------------\n'
check 'global view properties' "$(kr General GlobalViewProps)" true
check 'full path' "$(kr General ShowFullPath)" true
check 'tooltips' "$(kr General ShowToolTips)" false
check 'selection toggles' "$(kr General ShowSelectionToggle)" false
check 'statusbar' "$(kr General ShowStatusBar)" Small
check 'zoom slider' "$(kr General ShowZoomSlider)" false
check 'panels locked' "$(kr General LockPanels)" true
check 'details icon size' "$(kr DetailsMode IconSize)" 22
check 'details preview size' "$(kr DetailsMode PreviewSize)" 32
check 'details left padding' "$(kr DetailsMode LeftPadding)" 8
check 'details right padding' "$(kr DetailsMode RightPadding)" 8
check 'full-row highlight' "$(kr DetailsMode HighlightEntireRow)" true
check 'relative dates' "$(kr ContentDisplay UseShortRelativeDates)" false
check 'places icon size' "$(kr 'KFileDialog Settings' 'Places Icons Static Size')" 22
check 'menubar' "$(kr MainWindow MenuBar)" Disabled
TBM_CONFIG="$(kr MainWindow ToolBarsMovable)"
TBM_STATE="$(ks MainWindow ToolBarsMovable)"
if [[ "$TBM_CONFIG" == Disabled || "$TBM_STATE" == Disabled ]]; then
  SRC='dolphinrc'; [[ "$TBM_STATE" == Disabled ]] && SRC='dolphinstaterc'
  printf 'OK      %-36s %s (%s)\n' 'toolbar movable' 'Disabled' "$SRC"; ((ok+=1))
else
  printf 'MISMATCH %-33s %s\n' 'toolbar movable' "dolphinrc=${TBM_CONFIG:-<empty>} state=${TBM_STATE:-<empty>} (want Disabled)"; ((fail+=1))
fi
check 'toolbar button style' "$(kr 'MainWindow Toolbar mainToolBar' ToolButtonStyle)" IconOnly

UI="$HOME/.local/share/kxmlgui5/dolphin/dolphinui.rc"
check_file 'FIELD Dolphin toolbar override' "$UI"
if [[ -f "$UI" ]]; then
  if grep -q 'FIELD // FILES' "$UI" && grep -q 'name="url_navigators"' "$UI" && grep -q 'name="details"' "$UI"; then
    printf 'OK      %-36s %s\n' 'FIELD reduced toolbar' 'navigation + path + details + tools'; ((ok+=1))
  else
    printf 'MISMATCH %-33s %s\n' 'FIELD reduced toolbar' 'override exists but FIELD toolbar markers missing'; ((fail+=1))
  fi
fi

GLOBAL="$HOME/.local/share/dolphin/view_properties/global"
VIEW_RESULT="$(python3 - "$GLOBAL" <<'PY' 2>/dev/null || true
import os, pathlib, sys
p=pathlib.Path(sys.argv[1])
try:
    v=os.getxattr(p,b'user.kde.fm.viewproperties#1').decode('utf-8','replace')
except OSError:
    print('NO_XATTR')
else:
    ok='ViewMode=1' in v and 'SortFoldersFirst=true' in v and 'PreviewsShown=true' in v
    print('OK_XATTR' if ok else 'BAD_XATTR')
PY
)"
case "$VIEW_RESULT" in
  OK_XATTR) printf 'OK      %-36s %s\n' 'default global view' 'Details via xattr'; ((ok+=1)) ;;
  *)
    if [[ -f "$GLOBAL/.directory" ]] && grep -q '^ViewMode=1$' "$GLOBAL/.directory"; then
      printf 'OK      %-36s %s\n' 'default global view' 'Details via .directory fallback'; ((ok+=1))
    else
      printf 'MISMATCH %-33s %s\n' 'default global view' 'Details view metadata missing'; ((fail+=1))
    fi
    ;;
esac

if pgrep -x dolphin >/dev/null 2>&1; then
  printf 'INFO    %-36s %s\n' 'Dolphin process' 'running — close/reopen once after apply'; ((info+=1))
fi
printf '\nFIELD // DOLPHIN DOCTOR: %d OK / %d issue(s) / %d info\n' "$ok" "$fail" "$info"
(( fail == 0 ))
