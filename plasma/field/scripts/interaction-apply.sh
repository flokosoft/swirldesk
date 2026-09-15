#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
FIELD="$ROOT/plasma/field"
APPDIR="$HOME/.local/share/applications"
KGADIR="$HOME/.local/share/kglobalaccel"

if ! command -v kwriteconfig6 >/dev/null 2>&1; then
  echo 'kwriteconfig6 not found; Plasma 6 tools are required.' >&2
  exit 1
fi

[[ -x "$FIELD/scripts/interaction-backup.sh" ]] && "$FIELD/scripts/interaction-backup.sh" || true
mkdir -p "$APPDIR" "$KGADIR"

# FIELD 0.9.3.6: resolve the Meta+B conflict in the *live* KGlobalAccel
# daemon, not only in kglobalshortcutsrc. 0.9.3.4 changed the file while the
# daemon still held PowerDevil's old Battery + Meta+B mapping in memory.
# Qt::Key_Battery is 0x010000fe = 16777470.
if command -v gdbus >/dev/null 2>&1; then
  POWER_ACTION="['org_kde_powerdevil', 'powerProfile', '', '']"
  gdbus call --session --dest org.kde.kglobalaccel --object-path /kglobalaccel \
    --method org.kde.KGlobalAccel.setShortcut \
    "$POWER_ACTION" '[16777470]' 4 >/dev/null 2>&1 || true
  # Mirror KGlobalAccel's configuration-action path so the running PowerDevil
  # instance is notified immediately as well.
  gdbus call --session --dest org.kde.kglobalaccel --object-path /kglobalaccel \
    --method org.kde.KGlobalAccel.setForeignShortcut \
    "$POWER_ACTION" '[16777470]' >/dev/null 2>&1 || true
fi
kwriteconfig6 --file kglobalshortcutsrc --group org_kde_powerdevil \
  --key powerProfile 'Battery,Battery,Energieprofil wechseln'

# Workspace move+follow actions are deliberately NOT pre-written here. The
# loader now purges their live KGlobalAccel registrations and disk entries,
# then lets registerShortcut() create all six from a clean state.

# Six FIELD workspaces in one row.
kwriteconfig6 --file kwinrc --group Desktops --key Number 6
kwriteconfig6 --file kwinrc --group Desktops --key Rows 1
for n in 1 2 3 4 5 6; do
  kwriteconfig6 --file kwinrc --group Desktops --key "Name_$n" "$n"
  kwriteconfig6 --file kglobalshortcutsrc --group plasmashell \
    --key "activate task manager entry $n" "none,Meta+$n,Activate Task Manager Entry $n"
  kwriteconfig6 --file kglobalshortcutsrc --group plasma-desktop \
    --key "activate task manager entry $n" "none,Meta+$n,Activate Task Manager Entry $n"
  kwriteconfig6 --file kglobalshortcutsrc --group kwin \
    --key "Switch to Desktop $n" "Meta+$n,Ctrl+F$n,Switch to Desktop $n"
  # FIELD 0.8.8: move+follow is handled by the session KWin script below.
  kwriteconfig6 --file kglobalshortcutsrc --group kwin \
    --key "Window to Desktop $n" "none,none,Window to Desktop $n"
  # Release old experimental FIELD move+follow action IDs to avoid conflicts.
  kwriteconfig6 --file kglobalshortcutsrc --group kwin \
    --key "FIELD Move+Follow Desktop $n" "none,none,FIELD // Move active window to desktop $n and follow"
done

kwriteconfig6 --file kglobalshortcutsrc --group kwin --key 'Window Close' 'Meta+Q,Alt+F4,Close Window'
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key 'Window Fullscreen' 'Meta+F,none,Make Window Fullscreen'
kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key 'manage activities' 'none,Meta+Q,Activities...'
kwriteconfig6 --file kglobalshortcutsrc --group plasma-desktop --key 'manage activities' 'none,Meta+Q,Activities...'
kwriteconfig6 --file kglobalshortcutsrc --group org.kde.krunner.desktop --key _launch 'Meta+Space,Alt+Space;Alt+F2,FIELD // Launcher'
# Disable Spectacle's built-in bindings; FIELD registers its own command shortcuts
# below using the same mechanism already proven for Konsole/Dolphin/Firefox.
kwriteconfig6 --file kglobalshortcutsrc --group org.kde.spectacle.desktop --key _launch 'none,Print,Launch Spectacle'
kwriteconfig6 --file kglobalshortcutsrc --group org.kde.spectacle.desktop --key RectangularRegionScreenShot 'none,Meta+Shift+Print,Rectangular Region Screenshot'
kwriteconfig6 --file kglobalshortcutsrc --group org.kde.spectacle.desktop --key ActiveWindowScreenShot 'none,Meta+Print,Active Window Screenshot'
kwriteconfig6 --file kglobalshortcutsrc --group org.kde.spectacle.desktop --key FullScreenScreenShot 'none,Shift+Print,Full Screen Screenshot'
kwriteconfig6 --file kglobalshortcutsrc --group ksmserver --key 'Lock Session' 'Meta+L,Meta+L,Lock Session'

# FIELD // Plasma 0.5.3
# Use KDE's native command-shortcut mechanism exactly like KMenuEdit:
#   - hidden .desktop service
#   - X-KDE-GlobalAccel-CommandShortcut=true
#   - copy in ~/.local/share/kglobalaccel
#   - TOP-LEVEL component group in kglobalshortcutsrc
#   - absolute Exec path
# Previous builds incorrectly nested the component below [services] and used
# relative Exec= commands. Both can prevent Plasma 6 from launching the app.

# Disable/remove the experimental KWin launcher engine from 0.5.2.
kwriteconfig6 --file kwinrc --group Plugins --key swirldesk-field-launchersEnabled false 2>/dev/null || true
rm -rf "$HOME/.local/share/kwin/scripts/swirldesk-field-launchers"
rm -f "$HOME/.local/share/dbus-1/services/org.swirldesk.FieldLauncher.service"

find_app() {
  local name="$1" fallback="${2:-}"
  local p=''
  p="$(command -v "$name" 2>/dev/null || true)"
  if [[ -z "$p" && -n "$fallback" ]]; then
    p="$(command -v "$fallback" 2>/dev/null || true)"
  fi
  [[ -n "$p" ]] || return 1
  readlink -f "$p" 2>/dev/null || printf '%s\n' "$p"
}

KONSOLE="$(find_app konsole)" || { echo 'Konsole not found.' >&2; exit 1; }
DOLPHIN="$(find_app dolphin)" || { echo 'Dolphin not found.' >&2; exit 1; }
FIREFOX="$(find_app firefox firefox-esr)" || { echo 'Firefox/firefox-esr not found.' >&2; exit 1; }
# FIELD 0.8.6: Spectacle is optional, but the variable must always exist because
# this script runs with `set -u`. 0.8.5 referenced an unset variable here and
# aborted before screenshot launchers and the KWin workspace package were installed.
SPECTACLE="$(find_app spectacle || true)"

write_launcher() {
  local file="$1" name="$2" exec_path="$3" icon="$4" shortcut="$5"
  cat > "$APPDIR/$file" <<DESKTOP
[Desktop Entry]
Type=Application
Name=$name
Comment=SwirlDesk FIELD // Plasma launcher
Exec=$exec_path
Icon=$icon
NoDisplay=true
StartupNotify=false
X-KDE-GlobalAccel-CommandShortcut=true
DESKTOP
  install -m 0644 "$APPDIR/$file" "$KGADIR/$file"
  # KGlobalAccel component groups are top-level groups named after the desktop file.
  kwriteconfig6 --file kglobalshortcutsrc --group "$file" \
    --key _k_friendly_name "$name"
  kwriteconfig6 --file kglobalshortcutsrc --group "$file" \
    --key _launch "$shortcut,none,$name"
}

write_launcher 'org.swirldesk.field.konsole.desktop' 'FIELD // Terminal' "$KONSOLE" 'utilities-terminal' 'Meta+Return'
write_launcher 'org.swirldesk.field.dolphin.desktop' 'FIELD // Files' "$DOLPHIN" 'system-file-manager' 'Meta+E'
write_launcher 'org.swirldesk.field.firefox.desktop' 'FIELD // Browser' "$FIREFOX" 'firefox' 'Meta+B'

# FIELD // Capture. Spectacle is not guaranteed to be installed when Plasma
# was installed with --no-install-recommends, so do not abort FIELD setup.
CAPTURE_HELPER="$FIELD/scripts/plasma-screenshot.sh"
write_command_launcher() {
  local file="$1" name="$2" exec_line="$3" icon="$4" shortcut="$5"
  cat > "$APPDIR/$file" <<DESKTOP
[Desktop Entry]
Type=Application
Name=$name
Comment=SwirlDesk FIELD // Plasma command
Exec=$exec_line
Icon=$icon
NoDisplay=true
StartupNotify=false
X-KDE-GlobalAccel-CommandShortcut=true
DESKTOP
  install -m 0644 "$APPDIR/$file" "$KGADIR/$file"
  kwriteconfig6 --file kglobalshortcutsrc --group "$file" --key _k_friendly_name "$name"
  kwriteconfig6 --file kglobalshortcutsrc --group "$file" --key _launch "$shortcut,none,$name"
}

if [[ -n "$SPECTACLE" ]]; then
  write_command_launcher 'org.swirldesk.field.screenshot.area.desktop'   'FIELD // Capture Area'   "$CAPTURE_HELPER area" 'spectacle' 'Print'
  write_command_launcher 'org.swirldesk.field.screenshot.window.desktop' 'FIELD // Capture Window' "$CAPTURE_HELPER window" 'spectacle' 'Meta+Print'
  write_command_launcher 'org.swirldesk.field.screenshot.screen.desktop' 'FIELD // Capture Screen' "$CAPTURE_HELPER screen" 'spectacle' 'Ctrl+Print'
else
  echo 'WARNING: Spectacle is not installed; FIELD screenshot shortcuts were skipped.' >&2
  echo '         Install it with: sudo apt install kde-spectacle' >&2
  for f in org.swirldesk.field.screenshot.area.desktop org.swirldesk.field.screenshot.window.desktop org.swirldesk.field.screenshot.screen.desktop; do
    rm -f "$APPDIR/$f" "$KGADIR/$f"
    kwriteconfig6 --file kglobalshortcutsrc --group "$f" --key _launch 'none,none,FIELD // Capture' 2>/dev/null || true
  done
fi

# FIELD 0.8.9: restore the Hyprland-style quick application picker on
# Meta+Ctrl+Return. The panel's Kickoff icon remains clickable, but its global
# shortcut is released so KGlobalAccel can give the key to the FIELD launcher.
LAUNCHER_HELPER="$FIELD/scripts/plasma-launcher.sh"
chmod +x "$LAUNCHER_HELPER"

QDBUS_PLASMA=''
for c in qdbus6 qdbus-qt6 qdbus; do
  if command -v "$c" >/dev/null 2>&1; then QDBUS_PLASMA="$c"; break; fi
done
if [[ -n "$QDBUS_PLASMA" ]] && pgrep -x plasmashell >/dev/null 2>&1; then
  "$QDBUS_PLASMA" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
    panels().forEach(function(p) {
      p.widgets().forEach(function(w) {
        if (w.type === "org.kde.plasma.kickoff") {
          w.globalShortcut = "";
        }
      });
    });
  ' >/dev/null 2>&1 || true
fi

write_command_launcher 'org.swirldesk.field.applauncher.desktop' \
  'FIELD // Quick Launch' "$LAUNCHER_HELPER" 'system-run' 'Meta+Ctrl+Return'


# FIELD 0.8.8: permanent KWin move+follow engine for the German keyboard layout.
#
# The live KWin test proved two things on this machine:
#   1. dynamic KWin /Scripting loading works, and
#   2. KWin registerShortcut() works when Shift+number is registered as the
#      resulting German keysym (!, ", §, $, %, &).
#
# Keep one KWin script loaded for the whole Plasma session. It registers all
# six shortcuts directly inside KWin and performs move+follow without
# KGlobalAccel .desktop launchers or per-key runtime script creation.
MOVE_LOADER="$FIELD/scripts/field-workspaces-load.sh"
MOVE_SCRIPT="$FIELD/scripts/field-workspaces-de.js"
MOVE_AUTOSTART="$HOME/.config/autostart/org.swirldesk.field.kwin-workspaces.desktop"
chmod +x "$MOVE_LOADER"
mkdir -p "$HOME/.config/autostart"

# Remove every older FIELD move+follow implementation so there is one owner.
if command -v kpackagetool6 >/dev/null 2>&1; then
  kpackagetool6 --type=KWin/Script --remove swirldesk-field-workspaces >/dev/null 2>&1 || true
fi
rm -rf "$HOME/.local/share/kwin/scripts/swirldesk-field-workspaces"
kwriteconfig6 --file kwinrc --group Plugins --key swirldesk-field-workspacesEnabled false 2>/dev/null || true
rm -f "$FIELD/scripts/plasma-move-follow.sh"
for n in 1 2 3 4 5 6; do
  f="org.swirldesk.field.movefollow${n}.desktop"
  rm -f "$APPDIR/$f" "$KGADIR/$f"
  kwriteconfig6 --file kglobalshortcutsrc --group "$f" --key _launch "none,none,FIELD // Move+Follow Desktop $n" 2>/dev/null || true
  kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop $n" "none,none,Window to Desktop $n"
done

cat > "$MOVE_AUTOSTART" <<DESKTOP
[Desktop Entry]
Type=Application
Name=FIELD // Workspace Engine
Comment=SwirlDesk FIELD // Plasma move+follow shortcuts
Exec=$MOVE_LOADER
NoDisplay=true
OnlyShowIn=KDE;
StartupNotify=false
DESKTOP
chmod 0644 "$MOVE_AUTOSTART"

# Load immediately when apply is run inside an active Plasma/KWin session.
# The autostart entry takes care of all future logins.
if pgrep -x kwin_wayland >/dev/null 2>&1 || pgrep -x kwin_x11 >/dev/null 2>&1; then
  "$MOVE_LOADER" || echo 'WARNING: FIELD workspace engine could not be loaded live; it will retry on next Plasma login.' >&2
fi

# FIELD power panel. Use the same native KGlobalAccel command mechanism that
# already works for Konsole/Dolphin/Firefox.
POWER="$FIELD/scripts/plasma-power-toggle.sh"
cat > "$APPDIR/org.swirldesk.field.power.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=FIELD // Power
Comment=SwirlDesk FIELD // Plasma power control
Exec=$POWER
Icon=system-shutdown
NoDisplay=true
StartupNotify=false
X-KDE-GlobalAccel-CommandShortcut=true
DESKTOP
install -m 0644 "$APPDIR/org.swirldesk.field.power.desktop" "$KGADIR/org.swirldesk.field.power.desktop"
kwriteconfig6 --file kglobalshortcutsrc --group org.swirldesk.field.power.desktop --key _k_friendly_name 'FIELD // Power'
kwriteconfig6 --file kglobalshortcutsrc --group org.swirldesk.field.power.desktop --key _launch 'Meta+P,none,FIELD // Power'

command -v kbuildsycoca6 >/dev/null 2>&1 && kbuildsycoca6 --noincremental >/dev/null 2>&1 || true

QDBUS=''
for c in qdbus6 qdbus-qt6 qdbus; do
  if command -v "$c" >/dev/null 2>&1; then QDBUS="$c"; break; fi
done
if [[ -n "$QDBUS" ]] && pgrep -x kwin_wayland >/dev/null 2>&1; then
  "$QDBUS" org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
fi

cat <<TXT

FIELD // PLASMA INTERACTION 0.9.3.6 APPLIED

  APPLICATIONS
    Meta+Return        Konsole  ($KONSOLE)
    Meta+E             Dolphin ($DOLPHIN)
    Meta+B             Firefox ($FIREFOX)
    Meta+Space         KRunner // universal search
    Meta+Ctrl+Return   FIELD // Quick Launch (Fuzzel, Hyprland-style)
    Meta+P             FIELD // PWR

  WORKSPACES
    Meta+1..6          select workspace 1..6
    Meta+Shift+1..6    KWin native FIELD script: move active window + follow (DE layout)

The workspace engine is loaded immediately when KWin is running and is also
registered for Plasma autostart. No logout should be necessary.

Then run:
  swirl-field plasma interaction doctor
TXT
