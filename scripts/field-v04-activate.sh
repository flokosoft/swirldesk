#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
FIELD="$ROOT/themes/swirldesk-field"

if [ ! -d "$FIELD" ]; then
    echo "FIELD theme not found: $FIELD" >&2
    exit 1
fi

# Keep the existing selected theme; only apply v0.4 extras when FIELD is active.
current="$(readlink -f "$ROOT/state/current_theme" 2>/dev/null || true)"
if [ "$current" != "$FIELD" ]; then
    echo "FIELD is installed but not active. Select swirldesk-field with SUPER+SHIFT+T."
    exit 0
fi

mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0" "$HOME/.config/kitty"
ln -sfn "$FIELD/gtk/settings.ini" "$HOME/.config/gtk-3.0/settings.ini"
ln -sfn "$FIELD/gtk/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"
ln -sfn "$FIELD/gtk/gtk-3.css" "$HOME/.config/gtk-3.0/gtk.css"
ln -sfn "$FIELD/gtk/gtk-4.css" "$HOME/.config/gtk-4.0/gtk.css"
ln -sfn "$FIELD/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
ln -sfn "$FIELD/starship/starship.toml" "$HOME/.config/starship.toml"
ln -sfn "$FIELD/waybar/config" "$HOME/.config/waybar/config"
ln -sfn "$FIELD/waybar/style.css" "$HOME/.config/waybar/style.css"

"$ROOT/scripts/restart-ui.sh"

echo "SwirlDesk FIELD v0.4 active."
echo "Open a new terminal to see the FIELD prompt; restart GTK apps (e.g. Thunar) for GTK CSS."
