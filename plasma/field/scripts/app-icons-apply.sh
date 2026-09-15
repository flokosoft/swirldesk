#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
SRC="$ROOT/plasma/field/icons/SwirlDesk-FIELD-Plasma"
DST="$HOME/.local/share/icons/SwirlDesk-FIELD-Plasma"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backups/plasma-app-icons/$STAMP"
TRAY_SYS="/usr/share/plasma/plasmoids/org.kde.plasma.private.systemtray"
TRAY_DST="$HOME/.local/share/plasma/plasmoids/org.kde.plasma.private.systemtray"
TRAY_BACKUP="$ROOT/backups/plasma-systemtray/$STAMP"

ALIASES=(
  utilities-terminal.svg konsole.svg org.kde.konsole.svg
  system-file-manager.svg dolphin.svg org.kde.dolphin.svg
  brave-browser.svg brave.svg com.brave.Browser.svg
  firefox.svg firefox-esr.svg org.mozilla.firefox.svg org.mozilla.firefox-esr.svg
  signal-desktop.svg signal.svg org.signal.Signal.svg org.whispersystems.signal-desktop.svg
  signal-desktop-symbolic.svg signal-symbolic.svg org.signal.Signal-symbolic.svg org.whispersystems.signal-desktop-symbolic.svg
  bitwarden.svg Bitwarden.svg com.bitwarden.desktop.svg
  bitwarden-symbolic.svg Bitwarden-symbolic.svg com.bitwarden.desktop-symbolic.svg
  nextcloud.svg Nextcloud.svg com.nextcloud.desktopclient.nextcloud.svg nextcloud-desktop-client.svg
  nextcloud-symbolic.svg Nextcloud-symbolic.svg com.nextcloud.desktopclient.nextcloud-symbolic.svg nextcloud-desktop-client-symbolic.svg
)

if [[ ! -f "$SRC/index.theme" ]]; then
  echo "FIELD // icon source missing: $SRC/index.theme" >&2
  exit 1
fi

mkdir -p "$DST/scalable/apps" "$BACKUP" "$ROOT/state"
for name in "${ALIASES[@]}"; do
  if [[ -e "$DST/scalable/apps/$name" || -L "$DST/scalable/apps/$name" ]]; then
    cp -a "$DST/scalable/apps/$name" "$BACKUP/$name"
  fi
done
printf '%s\n' "$BACKUP" > "$ROOT/state/plasma_app_icons_last_backup"

install -m 0644 "$SRC/index.theme" "$DST/index.theme"
for base in field-terminal.svg field-files.svg field-browser-b.svg field-browser-f.svg field-chat.svg field-vault.svg field-cloud.svg; do
  install -m 0644 "$SRC/scalable/apps/$base" "$DST/scalable/apps/$base"
done

cd "$DST/scalable/apps"
rm -f "${ALIASES[@]}"
ln -s field-terminal.svg utilities-terminal.svg
ln -s field-terminal.svg konsole.svg
ln -s field-terminal.svg org.kde.konsole.svg
ln -s field-files.svg system-file-manager.svg
ln -s field-files.svg dolphin.svg
ln -s field-files.svg org.kde.dolphin.svg
ln -s field-browser-b.svg brave-browser.svg
ln -s field-browser-b.svg brave.svg
ln -s field-browser-b.svg com.brave.Browser.svg
ln -s field-browser-f.svg firefox.svg
ln -s field-browser-f.svg firefox-esr.svg
ln -s field-browser-f.svg org.mozilla.firefox.svg
ln -s field-browser-f.svg org.mozilla.firefox-esr.svg
for name in signal-desktop.svg signal.svg org.signal.Signal.svg org.whispersystems.signal-desktop.svg signal-desktop-symbolic.svg signal-symbolic.svg org.signal.Signal-symbolic.svg org.whispersystems.signal-desktop-symbolic.svg; do ln -s field-chat.svg "$name"; done
for name in bitwarden.svg Bitwarden.svg com.bitwarden.desktop.svg bitwarden-symbolic.svg Bitwarden-symbolic.svg com.bitwarden.desktop-symbolic.svg; do ln -s field-vault.svg "$name"; done
for name in nextcloud.svg Nextcloud.svg com.nextcloud.desktopclient.nextcloud.svg nextcloud-desktop-client.svg nextcloud-symbolic.svg Nextcloud-symbolic.svg com.nextcloud.desktopclient.nextcloud-symbolic.svg nextcloud-desktop-client-symbolic.svg; do ln -s field-cloud.svg "$name"; done
cd - >/dev/null

if command -v kwriteconfig6 >/dev/null 2>&1; then
  kwriteconfig6 --file kdeglobals --group Icons --key Theme SwirlDesk-FIELD-Plasma
fi

# FIELD 0.9.3.7: install a deterministic Plasma 6.3.5 tray delegate instead of
# editing QML in-place. 0.9.3.6 successfully installed the vectors on the
# affected machine, but the local StatusNotifierItem.qml itself stayed at the
# old revision. Direct replacement removes that failure mode.
TRAY_TEMPLATE="$ROOT/plasma/field/tray/StatusNotifierItem.qml"
SYSTEM_QML="$TRAY_SYS/contents/ui/items/StatusNotifierItem.qml"
LOCAL_QML="$TRAY_DST/contents/ui/items/StatusNotifierItem.qml"

if [[ ! -f "$TRAY_TEMPLATE" ]]; then
  echo "FIELD // tray template missing: $TRAY_TEMPLATE" >&2
  exit 1
fi

# Prefer a fresh copy of the system plasmoid when available. If the distro
# keeps the system tray elsewhere but a previous FIELD local copy already
# exists, keep that complete plasmoid and only replace its delegate below.
if [[ -d "$TRAY_SYS" && -f "$SYSTEM_QML" ]]; then
  if [[ -d "$TRAY_DST" ]]; then
    mkdir -p "$(dirname "$TRAY_BACKUP")"
    cp -a "$TRAY_DST" "$TRAY_BACKUP"
    printf '%s\n' "$TRAY_BACKUP" > "$ROOT/state/plasma_systemtray_last_backup"
  else
    : > "$ROOT/state/plasma_systemtray_last_backup"
  fi

  rm -rf "$TRAY_DST"
  mkdir -p "$(dirname "$TRAY_DST")"
  cp -a "$TRAY_SYS" "$TRAY_DST"
elif [[ -d "$TRAY_DST" && -f "$LOCAL_QML" ]]; then
  mkdir -p "$(dirname "$TRAY_BACKUP")"
  cp -a "$TRAY_DST" "$TRAY_BACKUP"
  printf '%s\n' "$TRAY_BACKUP" > "$ROOT/state/plasma_systemtray_last_backup"
  echo "FIELD // system tray source not found; reusing existing local plasmoid"
else
  echo "FIELD // Plasma system tray plasmoid not found (system or local)" >&2
  exit 1
fi

TRAY_ICONS="$TRAY_DST/contents/icons"
mkdir -p "$TRAY_ICONS" "$(dirname "$LOCAL_QML")"
install -m 0644 "$SRC/scalable/apps/field-chat.svg" "$TRAY_ICONS/field-chat.svg"
install -m 0644 "$SRC/scalable/apps/field-vault.svg" "$TRAY_ICONS/field-vault.svg"
install -m 0644 "$TRAY_TEMPLATE" "$LOCAL_QML"

# Verify the exact delegate which Plasma will load, not the source script.
if ! grep -Fq 'FIELD 0.9.3.7 DIRECT SNI OVERRIDE' "$LOCAL_QML" || \
   ! grep -Fq 'Qt.resolvedUrl("../../icons/field-chat.svg")' "$LOCAL_QML" || \
   ! grep -Fq 'Qt.resolvedUrl("../../icons/field-vault.svg")' "$LOCAL_QML" || \
   ! grep -Fq 'isMask: taskIcon.fieldHasOverride' "$LOCAL_QML"; then
  echo "FIELD // direct StatusNotifierItem.qml install verification failed" >&2
  exit 1
fi

if command -v kbuildsycoca6 >/dev/null 2>&1; then
  kbuildsycoca6 --noincremental >/dev/null 2>&1 || kbuildsycoca6 >/dev/null 2>&1 || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t "$DST" >/dev/null 2>&1 || true
fi

if systemctl --user is-active plasma-plasmashell.service >/dev/null 2>&1; then
  systemctl --user restart plasma-plasmashell.service || true
elif command -v kquitapp6 >/dev/null 2>&1 && command -v kstart >/dev/null 2>&1; then
  kquitapp6 plasmashell >/dev/null 2>&1 || true
  (kstart plasmashell >/dev/null 2>&1 &) || true
fi

echo "FIELD // RECOGNIZABLE MONOCHROME PANEL APPLIED"
echo "  Signal     FIELD speech-bubble vector (direct tray source)"
echo "  Bitwarden  FIELD shield/keyhole vector (direct tray source)"
echo "  other tray StatusNotifier items retain Plasma normal rendering"
echo "  attention/hover -> Coyote"
