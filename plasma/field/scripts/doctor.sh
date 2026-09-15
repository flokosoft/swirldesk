#!/usr/bin/env bash
set -u
ROOT="$HOME/.config/swirldesk"
FIELD="$ROOT/plasma/field"
ok(){ printf 'OK      %s\n' "$1"; }
warn(){ printf 'WARN    %s\n' "$1"; }
fail(){ printf 'MISSING %s\n' "$1"; }

echo 'FIELD // PLASMA DOCTOR'
echo '----------------------'
for c in startplasma-wayland plasmashell plasma-apply-colorscheme plasma-apply-wallpaperimage konsole; do
  command -v "$c" >/dev/null 2>&1 && ok "$c" || fail "$c"
done
command -v plasma-apply-desktoptheme >/dev/null 2>&1 && ok plasma-apply-desktoptheme || warn 'plasma-apply-desktoptheme (fallback via plasmarc available)'
command -v kwriteconfig6 >/dev/null 2>&1 && ok kwriteconfig6 || warn 'kwriteconfig6 (recommended)'
[[ -f "$FIELD/colors/SwirlDeskFIELD.colors" ]] && ok 'FIELD color scheme source' || fail 'FIELD color scheme source'
[[ -f "$HOME/.local/share/color-schemes/SwirlDeskFIELD.colors" ]] && ok 'FIELD color scheme installed' || warn 'FIELD color scheme not installed yet'
[[ -f "$FIELD/style/SwirlDeskFIELD/metadata.json" ]] && ok 'FIELD Plasma style source' || fail 'FIELD Plasma style source'
[[ -f "$HOME/.local/share/plasma/desktoptheme/SwirlDeskFIELD/metadata.json" ]] && ok 'FIELD Plasma style installed' || warn 'FIELD Plasma style not installed yet'
[[ -f "$HOME/.local/share/plasma/plasmoids/org.swirldesk.fieldlabel/metadata.json" ]] && ok 'FIELD // rail widget installed' || warn 'FIELD // rail widget not installed yet'
[[ -f "$HOME/.local/share/konsole/SwirlDeskFIELD.colorscheme" ]] && ok 'Konsole FIELD color scheme installed' || warn 'Konsole FIELD color scheme not installed yet'
[[ -f "$HOME/.local/share/konsole/SwirlDesk FIELD.profile" ]] && ok 'Konsole FIELD profile installed' || warn 'Konsole FIELD profile not installed yet'
[[ -f "$HOME/.local/share/icons/SwirlDesk-FIELD-Plasma/index.theme" ]] && ok 'FIELD Plasma icon overlay installed' || warn 'FIELD Plasma icon overlay not installed yet'
if command -v kreadconfig6 >/dev/null 2>&1; then
  [[ "$(kreadconfig6 --file kdeglobals --group Icons --key Theme 2>/dev/null)" == 'SwirlDesk-FIELD-Plasma' ]] && ok 'FIELD Plasma icon theme active' || warn 'FIELD Plasma icon theme not active'
  [[ "$(kreadconfig6 --file kdeglobals --group General --key AccentColor 2>/dev/null)" == '166,138,91' ]] && ok 'Coyote Plasma accent active' || warn 'Plasma accent is not pinned to Coyote'
fi
for p in clean aor1 multicam; do
  case "$p" in
    clean) f="$ROOT/wallpapers/SwirlDeskFIELD/field-topo-minimal-1920x1200.png" ;;
    aor1) f="$ROOT/wallpapers/SwirlDeskFIELD/field-topo-aor1-ghost-1920x1200.png" ;;
    multicam) f="$ROOT/wallpapers/SwirlDeskFIELD/field-topo-multicam-ghost-1920x1200.png" ;;
  esac
  [[ -f "$f" ]] && ok "wallpaper $p" || fail "wallpaper $p"
done
if pgrep -x plasmashell >/dev/null 2>&1; then ok 'Plasma session running'; else warn 'Plasma session not running'; fi
for unit in waybar.service dunst.service; do
  if systemctl --user is-enabled "$unit" 2>/dev/null | grep -q '^masked'; then
    ok "$unit masked for dual-session setup"
  elif systemctl --user is-active --quiet "$unit" 2>/dev/null; then
    warn "$unit ACTIVE in Plasma; run: $FIELD/scripts/session-guard.sh"
  else
    warn "$unit not masked; masking is recommended for Plasma/Hyprland dual sessions"
  fi
done
if [[ -L "$HOME/.config/gtk-3.0/settings.ini" ]]; then
  ok 'Hyprland GTK settings.ini remains symlinked'
else
  warn 'GTK settings.ini is not a symlink; review before changing GTK settings in Plasma'
fi
if [[ -L "$HOME/.config/gtk-3.0/gtk.css" ]]; then
  ok 'Hyprland GTK gtk.css remains symlinked'
else
  warn 'GTK gtk.css is not a symlink; review shared GTK styling'
fi
printf '\nProfile: %s\n' "$(cat "$ROOT/state/plasma_field_profile" 2>/dev/null || echo 'not set')"
if [[ -x "$FIELD/scripts/shell-doctor.sh" ]]; then
  echo
  "$FIELD/scripts/shell-doctor.sh" || true
fi

if [[ -x "$FIELD/scripts/notification-doctor.sh" ]]; then echo; "$FIELD/scripts/notification-doctor.sh" || true; fi
