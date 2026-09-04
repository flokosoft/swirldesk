#!/usr/bin/env bash
set -u
ROOT="$HOME/.config/swirldesk"
ACTIVE=$(cat "$ROOT/state/current_theme_name" 2>/dev/null || true)

# FIELD gets the native panel. Other SwirlDesk themes keep the compact Fuzzel
# power menu, so this remains reversible and does not alter the shared UX.
if [ "$ACTIVE" = "swirldesk-field" ] && python3 - <<'PY' >/dev/null 2>&1
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk
PY
then
    exec "$ROOT/scripts/field-power-toggle.sh"
fi

exec "$ROOT/scripts/power-menu-fallback.sh"
