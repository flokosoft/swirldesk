#!/usr/bin/env bash
set -euo pipefail

FIELD="$HOME/.config/swirldesk/plasma/field"
SCRIPT="$FIELD/scripts/field-workspaces-de.js"
NAME="swirldesk-field-workspaces-de"

[[ -r "$SCRIPT" ]] || { echo "FIELD: workspace script missing: $SCRIPT" >&2; exit 1; }

QDBUS=""
for c in qdbus6 qdbus-qt6 qdbus; do
  if command -v "$c" >/dev/null 2>&1; then
    QDBUS="$c"
    break
  fi
done
[[ -n "$QDBUS" ]] || { echo 'FIELD: qdbus6/qdbus-qt6 not found' >&2; exit 1; }

# Plasma autostart can race KWin very early in the session. Wait briefly for
# the scripting object instead of failing and leaving the shortcuts absent.
ready=0
for _ in $(seq 1 50); do
  if "$QDBUS" org.kde.KWin /Scripting >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 0.2
done
[[ "$ready" -eq 1 ]] || { echo 'FIELD: KWin scripting D-Bus service is not ready' >&2; exit 1; }

# FIELD 0.9.3.6: first unload every prior experimental/live instance. KWin
# registerShortcut() uses KGlobalAccel's autoloading semantics: if an action ID
# already exists, the daemon restores its stored shortcut and ignores the JS
# default. In 0.9.3.4 this meant the old diagnostic action still owned Meta+"
# at runtime while the real Desktop-2 action kept autoloading as "none".
for old in \
  "$NAME" \
  swirldesk-field-workspaces \
  field-shortcut-test \
  field-shortcut-test-de; do
  "$QDBUS" org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript "$old" >/dev/null 2>&1 || true
done

# Let KWin finish marking the old QAction objects inactive before we remove
# their KGlobalAccel registrations from another D-Bus connection.
sleep 0.2

# Purge the stale runtime registrations, not just their INI entries. This is
# the part 0.9.3.4 was missing. The modern unregister(component, action)
# method takes plain strings, so qdbus6 can call it reliably.
for action in \
  'FIELD MoveFollow DE Test' \
  'FIELD MoveFollow Test' \
  'FIELD DE MoveFollow Desktop 1' \
  'FIELD DE MoveFollow Desktop 2' \
  'FIELD DE MoveFollow Desktop 3' \
  'FIELD DE MoveFollow Desktop 4' \
  'FIELD DE MoveFollow Desktop 5' \
  'FIELD DE MoveFollow Desktop 6'; do
  "$QDBUS" org.kde.kglobalaccel /kglobalaccel \
    org.kde.KGlobalAccel.unregister kwin "$action" >/dev/null 2>&1 || true
done

# Remove any disk remnants as well. Fresh registerShortcut() calls below will
# recreate all six actions from their verified German-layout keysyms.
if command -v kwriteconfig6 >/dev/null 2>&1; then
  for action in \
    'FIELD MoveFollow DE Test' \
    'FIELD MoveFollow Test' \
    'FIELD DE MoveFollow Desktop 1' \
    'FIELD DE MoveFollow Desktop 2' \
    'FIELD DE MoveFollow Desktop 3' \
    'FIELD DE MoveFollow Desktop 4' \
    'FIELD DE MoveFollow Desktop 5' \
    'FIELD DE MoveFollow Desktop 6'; do
    kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "$action" --delete 2>/dev/null || true
  done
fi

ID="$("$QDBUS" org.kde.KWin /Scripting \
  org.kde.kwin.Scripting.loadScript "$SCRIPT" "$NAME" 2>/dev/null || true)"
[[ "$ID" =~ ^[0-9]+$ ]] || { echo 'FIELD: KWin refused workspace script' >&2; exit 1; }

"$QDBUS" org.kde.KWin "/Scripting/Script${ID}" org.kde.kwin.Script.run >/dev/null

# Deliberately do NOT unload it: registerShortcut() stays active only while the
# KWin script remains loaded for this Plasma session.
printf 'FIELD // workspace engine loaded fresh (script id %s)\n' "$ID"
