#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
FIELD="$ROOT/plasma/field"
STYLE_SRC="$FIELD/style/SwirlDeskFIELD"
STYLE_DST="$HOME/.local/share/plasma/desktoptheme/SwirlDeskFIELD"
PROFILE="$(cat "$ROOT/state/plasma_field_profile" 2>/dev/null || echo aor1)"

[[ -d "$STYLE_SRC" ]] || { echo 'FIELD Plasma style source missing.' >&2; exit 1; }
"$FIELD/scripts/shell-backup.sh" >/dev/null
mkdir -p "$HOME/.local/share/plasma/desktoptheme"
rm -rf "$STYLE_DST"
cp -a "$STYLE_SRC" "$STYLE_DST"

if command -v plasma-apply-desktoptheme >/dev/null 2>&1 && pgrep -x plasmashell >/dev/null 2>&1; then
  plasma-apply-desktoptheme SwirlDeskFIELD >/dev/null
elif command -v kwriteconfig6 >/dev/null 2>&1; then
  kwriteconfig6 --file plasmarc --group Theme --key name SwirlDeskFIELD
fi

"$FIELD/scripts/sync-lockscreen.sh" "$PROFILE" >/dev/null

if command -v kwriteconfig6 >/dev/null 2>&1; then
  kwriteconfig6 --file kdeglobals --group General --key accentColorFromWallpaper false
  kwriteconfig6 --file kdeglobals --group General --key AccentColor '166,138,91'
  kwriteconfig6 --file kdeglobals --group General --key LastUsedCustomAccentColor '166,138,91'
  kwriteconfig6 --file kdeglobals --group 'Colors:Accent' --key BackgroundNormal '166,138,91'
  kwriteconfig6 --file kdeglobals --group 'Colors:Accent' --key BackgroundAlternate '142,122,88'
  kwriteconfig6 --file kdeglobals --group 'Colors:Accent' --key ForegroundNormal '217,211,195'
fi
"$FIELD/scripts/session-guard.sh" || true
# Plasma caches SVG/style colors aggressively; remove user cache so the next
# shell/session cannot keep stale Breeze-blue popup assets.
rm -rf "$HOME/.cache/plasma"* 2>/dev/null || true

cat <<TXT
FIELD // PLASMA SHELL 0.8.4 APPLIED

  KRunner       FIELD dialog surface / Coyote top line
  popups        Graphite FIELD dialog surface
  tooltips      Graphite / Kangaroo edge
  notifications FIELD Dunst / identical to Hyprland
  lockscreen    ${PROFILE^^} FIELD wallpaper

Meta+Space continues to use native KRunner.
Meta+L continues to use native Plasma lock.
TXT

# Force Plasma/Kirigami to reload the current color roles.
for q in qdbus6 qdbus-qt6 qdbus; do
  if command -v "$q" >/dev/null 2>&1 && pgrep -x plasmashell >/dev/null 2>&1; then
    "$q" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.refreshCurrentShell >/dev/null 2>&1 || true
    break
  fi
done
