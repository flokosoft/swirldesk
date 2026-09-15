#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
DST="$HOME/.local/share/icons/SwirlDesk-FIELD-Plasma/scalable/apps"
BACKUP="${1:-$(cat "$ROOT/state/plasma_app_icons_last_backup" 2>/dev/null || true)}"
TRAY_DST="$HOME/.local/share/plasma/plasmoids/org.kde.plasma.private.systemtray"
TRAY_BACKUP="$(cat "$ROOT/state/plasma_systemtray_last_backup" 2>/dev/null || true)"
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

mkdir -p "$DST"
rm -f "$DST/field-terminal.svg" "$DST/field-files.svg" "$DST/field-browser-b.svg" "$DST/field-browser-f.svg" "$DST/field-chat.svg" "$DST/field-vault.svg" "$DST/field-cloud.svg"
for name in "${ALIASES[@]}"; do rm -f "$DST/$name"; done

if [[ -n "$BACKUP" && -d "$BACKUP" ]]; then
  for f in "$BACKUP"/*; do
    [[ -e "$f" || -L "$f" ]] || continue
    cp -a "$f" "$DST/"
  done
  echo "Restored prior app icon overrides from: $BACKUP"
else
  echo "No previous app-icon backup found; FIELD app overrides removed."
fi

rm -rf "$TRAY_DST"
if [[ -n "$TRAY_BACKUP" && -d "$TRAY_BACKUP" ]]; then
  cp -a "$TRAY_BACKUP" "$TRAY_DST"
  echo "Restored prior user system-tray override from: $TRAY_BACKUP"
else
  echo "Removed FIELD user-local system-tray override; Plasma will use the Debian system copy."
fi

command -v kbuildsycoca6 >/dev/null 2>&1 && kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
if systemctl --user is-active plasma-plasmashell.service >/dev/null 2>&1; then
  systemctl --user restart plasma-plasmashell.service || true
fi
echo "Close/reopen affected apps (or log out/in once) to flush cached task icons."
