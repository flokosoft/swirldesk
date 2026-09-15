#!/usr/bin/env bash
set -u
ROOT="$HOME/.config/swirldesk"
FIELD="$ROOT/plasma/field"
STYLE="$HOME/.local/share/plasma/desktoptheme/SwirlDeskFIELD"
ok(){ printf 'OK      %-34s %s\n' "$1" "${2:-}"; }
warn(){ printf 'WARN    %-34s %s\n' "$1" "${2:-}"; }
fail(){ printf 'MISSING %-34s %s\n' "$1" "${2:-}"; }
issues=0
for f in dialogs/background.svg widgets/background.svg widgets/tooltip.svg widgets/plasmoidheading.svg widgets/panel-background.svg; do
  if [[ -f "$STYLE/$f" ]]; then ok "Plasma style $f"; else fail "Plasma style $f"; issues=$((issues+1)); fi
done
if [[ -f "$HOME/.config/kscreenlockerrc" ]]; then
  ok 'kscreenlockerrc'
  img="$(kreadconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image 2>/dev/null || true)"
  [[ "$img" == *SwirlDeskFIELD* ]] && ok 'FIELD lockscreen wallpaper' "$img" || warn 'FIELD lockscreen wallpaper' "${img:-not set}"
else
  warn 'kscreenlockerrc' 'not created yet'
fi
if command -v plasma-apply-desktoptheme >/dev/null 2>&1; then ok 'plasma-apply-desktoptheme'; else warn 'plasma-apply-desktoptheme' 'plasmarc fallback only'; fi
if pgrep -x plasmashell >/dev/null 2>&1; then ok 'Plasma session' 'running'; else warn 'Plasma session' 'not running'; fi
printf '\nFIELD // SHELL DOCTOR: %d issue(s)\n' "$issues"
exit "$issues"

if command -v kreadconfig6 >/dev/null 2>&1; then
  accent="$(kreadconfig6 --file kdeglobals --group General --key AccentColor 2>/dev/null || true)"
  [[ "$accent" == '166,138,91' ]] && echo 'OK      Plasma accent Coyote (166,138,91)' || echo "WARN    Plasma accent: ${accent:-unset}"
fi
if [[ -x "$FIELD/scripts/notification-doctor.sh" ]]; then
  echo
  "$FIELD/scripts/notification-doctor.sh" || true
fi
