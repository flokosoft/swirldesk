#!/usr/bin/env bash
set -u
ok=0; fail=0
kr(){ kreadconfig6 --file "$1" --group "$2" --key "$3" 2>/dev/null || true; }
check(){
  local label="$1" actual="$2" expected="$3"
  if [[ "$actual" == "$expected" ]]; then
    printf 'OK      %-32s %s\n' "$label" "$actual"; ((ok+=1))
  else
    printf 'MISMATCH %-29s %s (want %s)\n' "$label" "$actual" "$expected"; ((fail+=1))
  fi
}
check 'decoration library' "$(kr kwinrc org.kde.kdecoration2 library)" 'org.kde.breeze'
check 'decoration theme' "$(kr kwinrc org.kde.kdecoration2 theme)" 'Breeze'
check 'border size' "$(kr kwinrc org.kde.kdecoration2 BorderSize)" 'Tiny'
check 'auto border size' "$(kr kwinrc org.kde.kdecoration2 BorderSizeAuto)" 'false'
check 'left title buttons' "$(kr kwinrc org.kde.kdecoration2 ButtonsOnLeft)" ''
check 'right title buttons' "$(kr kwinrc org.kde.kdecoration2 ButtonsOnRight)" 'IAX'
check 'blur' "$(kr kwinrc Plugins blurEnabled)" 'false'
check 'wobbly windows' "$(kr kwinrc Plugins wobblywindowsEnabled)" 'false'
check 'translucency' "$(kr kwinrc Plugins translucencyEnabled)" 'false'
printf '\nFIELD // WINDOW DOCTOR: %d OK / %d issue(s)\n' "$ok" "$fail"
(( fail == 0 ))
