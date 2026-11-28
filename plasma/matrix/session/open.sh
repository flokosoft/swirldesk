#!/usr/bin/env bash
set -eu
HERE=$(cd -- "$(dirname -- "$0")" && pwd)
"$HERE/guard.sh"
if python3 -c 'import gi; gi.require_version("Gtk","3.0"); from gi.repository import Gtk' 2>/dev/null; then exec python3 "$HERE/power.py"; fi
if command -v fuzzel >/dev/null; then exec "$HERE/fallback.sh"; fi
# Native KDE confirmation fallback.
for q in qdbus6 qdbus-qt6 qdbus; do if command -v "$q" >/dev/null; then exec "$q" org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptAll; fi; done
exit 1
