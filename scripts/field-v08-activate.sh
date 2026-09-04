#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
FIELD="$ROOT/themes/swirldesk-field"

"$ROOT/scripts/field-theme-check.sh" "$FIELD" >/dev/null

for script in \
    field-waybar-time.sh field-waybar-sys.sh field-waybar-comms.sh \
    field-waybar-power.sh field-status.sh field-status-toggle.sh \
    field-lock-status.sh notification-status.sh toggle-notifications.sh \
    dunst-start.sh power-menu.sh control-center.sh restart-ui.sh; do
    [ -x "$ROOT/scripts/$script" ] || chmod +x "$ROOT/scripts/$script"
done

current="$(readlink -f "$ROOT/state/current_theme" 2>/dev/null || true)"
if [ "$current" != "$FIELD" ]; then
    echo "FIELD v0.8 installed. Select swirldesk-field with SUPER+SHIFT+T."
    exit 0
fi

mkdir -p "$HOME/.config/waybar" "$HOME/.config/fuzzel"
ln -sfn "$FIELD/waybar/config" "$HOME/.config/waybar/config"
ln -sfn "$FIELD/waybar/style.css" "$HOME/.config/waybar/style.css"
ln -sfn "$FIELD/fuzzel/fuzzel.ini" "$HOME/.config/fuzzel/fuzzel.ini"

"$ROOT/scripts/restart-ui.sh"

echo "SwirlDesk FIELD v0.8 active."
echo "Visual cohesion: AUTH / NTF / PWR / STATUS use the FIELD instrument language."
