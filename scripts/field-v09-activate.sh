#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
FIELD="$ROOT/themes/swirldesk-field"

"$ROOT/scripts/field-theme-check.sh" "$FIELD" >/dev/null
chmod +x "$ROOT/scripts/"*.sh "$ROOT/scripts/field-control.py" 2>/dev/null || true

current="$(readlink -f "$ROOT/state/current_theme" 2>/dev/null || true)"
if [ "$current" != "$FIELD" ]; then
    echo "FIELD v0.9 installed. Select swirldesk-field with SUPER+SHIFT+T."
    exit 0
fi

mkdir -p "$HOME/.config/waybar" "$HOME/.config/fuzzel"
ln -sfn "$FIELD/waybar/config" "$HOME/.config/waybar/config"
ln -sfn "$FIELD/waybar/style.css" "$HOME/.config/waybar/style.css"
ln -sfn "$FIELD/fuzzel/fuzzel.ini" "$HOME/.config/fuzzel/fuzzel.ini"

hyprctl reload >/dev/null 2>&1 || true
"$ROOT/scripts/restart-ui.sh"

echo "SwirlDesk FIELD v0.9 active."
if python3 - <<'PY' >/dev/null 2>&1
import gi
gi.require_version('Gtk','3.0')
from gi.repository import Gtk
PY
then
    echo "SUPER+SPACE: native FIELD CONTROL"
else
    echo "SUPER+SPACE: Fuzzel fallback (install python3-gi + gir1.2-gtk-3.0 for native panel)"
fi
