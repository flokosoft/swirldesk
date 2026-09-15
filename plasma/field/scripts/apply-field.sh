#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
FIELD="$ROOT/plasma/field"
SCHEME_SRC="$FIELD/colors/SwirlDeskFIELD.colors"
SCHEME_DST="$HOME/.local/share/color-schemes/SwirlDeskFIELD.colors"
STYLE_SRC="$FIELD/style/SwirlDeskFIELD"
STYLE_DST="$HOME/.local/share/plasma/desktoptheme/SwirlDeskFIELD"
PLASMOID_SRC="$FIELD/plasmoid/org.swirldesk.fieldlabel"
PLASMOID_DST="$HOME/.local/share/plasma/plasmoids/org.swirldesk.fieldlabel"
KONSOLE_DIR="$HOME/.local/share/konsole"
PLASMA_ICON_SRC="$FIELD/icons/SwirlDesk-FIELD-Plasma"
PLASMA_ICON_DST="$HOME/.local/share/icons/SwirlDesk-FIELD-Plasma"
PROFILE="${1:-$(cat "$ROOT/state/plasma_field_profile" 2>/dev/null || echo aor1)}"

mkdir -p "$HOME/.local/share/color-schemes" "$HOME/.local/share/icons" \
         "$HOME/.local/share/plasma/desktoptheme" "$HOME/.local/share/plasma/plasmoids" \
         "$HOME/.config/autostart" "$KONSOLE_DIR" "$ROOT/state"
install -m 0644 "$SCHEME_SRC" "$SCHEME_DST"
rm -rf "$STYLE_DST" "$PLASMOID_DST"
cp -a "$STYLE_SRC" "$STYLE_DST"
cp -a "$PLASMOID_SRC" "$PLASMOID_DST"
install -m 0644 "$FIELD/konsole/SwirlDeskFIELD.colorscheme" "$KONSOLE_DIR/SwirlDeskFIELD.colorscheme"
install -m 0644 "$FIELD/konsole/SwirlDesk FIELD.profile" "$KONSOLE_DIR/SwirlDesk FIELD.profile"

rm -rf "$PLASMA_ICON_DST"
cp -a "$PLASMA_ICON_SRC" "$PLASMA_ICON_DST"

cat > "$HOME/.config/autostart/org.swirldesk.field.plasma-notification-guard.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=SwirlDesk FIELD Plasma Session Guard
Exec=$FIELD/scripts/session-guard.sh
OnlyShowIn=KDE;
NoDisplay=true
X-KDE-autostart-phase=0
DESKTOP

# Apply dual-session guard immediately too. Direct Hyprland launches remain valid
# even while the global user-systemd units are masked.
"$FIELD/scripts/session-guard.sh" || true

# Plasma-specific icon overlay: FIELD places/apps + Breeze Dark fallback.
# Konsole is intentionally the KDE terminal. This does not change Hyprland's SUPER+ENTER -> Kitty.
if command -v kwriteconfig6 >/dev/null 2>&1; then
  kwriteconfig6 --file kdeglobals --group General --key TerminalApplication konsole
  kwriteconfig6 --file kdeglobals --group General --key TerminalService org.kde.konsole.desktop
  kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile "SwirlDesk FIELD.profile"
  kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle Breeze
  kwriteconfig6 --file kdeglobals --group Icons --key Theme SwirlDesk-FIELD-Plasma
fi

if ! pgrep -x plasmashell >/dev/null 2>&1; then
  echo "FIELD // PLASMA assets installed."
  echo "Log into Plasma, then run: swirl-field plasma apply"
  exit 0
fi

if [[ ! -f "$ROOT/state/plasma_field_initialized" ]]; then
  "$FIELD/scripts/backup-plasma.sh"
  touch "$ROOT/state/plasma_field_initialized"
fi

plasma-apply-colorscheme SwirlDeskFIELD >/dev/null
# Do not let Breeze/wallpaper blue leak into Plasma/Kirigami controls.
kwriteconfig6 --file kdeglobals --group General --key accentColorFromWallpaper false
kwriteconfig6 --file kdeglobals --group General --key AccentColor '166,138,91'
kwriteconfig6 --file kdeglobals --group General --key LastUsedCustomAccentColor '166,138,91' 
if command -v plasma-apply-desktoptheme >/dev/null 2>&1; then
  plasma-apply-desktoptheme SwirlDeskFIELD >/dev/null
else
  kwriteconfig6 --file plasmarc --group Theme --key name SwirlDeskFIELD
fi

if command -v plasma-apply-cursortheme >/dev/null 2>&1; then
  if [[ -d "$HOME/.local/share/icons/Bibata-Modern-Classic/cursors" || -d "/usr/share/icons/Bibata-Modern-Classic/cursors" ]]; then
    plasma-apply-cursortheme Bibata-Modern-Classic >/dev/null || true
  fi
fi

"$FIELD/scripts/profile.sh" "$PROFILE"

echo
echo "FIELD // PLASMA 0.8 APPLIED"
echo "  colors    SwirlDesk FIELD"
echo "  plasma    SwirlDesk FIELD style / no blur"
echo "  terminal  Konsole / SwirlDesk FIELD profile"
echo "  icons     SwirlDesk-FIELD-Plasma / Breeze Dark fallback"
echo "  profile   ${PROFILE^^}"
echo
echo "Hyprland SUPER+ENTER still starts Kitty. KDE/Plasma terminal actions use Konsole."
echo "Re-apply the rail once so the FIELD // identity widget is added:"
echo "  swirl-field plasma panel apply"
