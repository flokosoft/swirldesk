#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
FIELD="$ROOT/themes/swirldesk-field"

"$ROOT/scripts/field-theme-check.sh" "$FIELD" >/dev/null

current="$(readlink -f "$ROOT/state/current_theme" 2>/dev/null || true)"
if [ "$current" != "$FIELD" ]; then
    echo "FIELD v0.6 installed. Select swirldesk-field with SUPER+SHIFT+T."
    exit 0
fi

mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0" "$HOME/.config/kitty" "$HOME/.config/waybar" "$HOME/.config/fuzzel" "$HOME/.config/dunst" "$HOME/.local/share/icons"
ln -sfn "$FIELD/icons/SwirlDesk-FIELD" "$HOME/.local/share/icons/SwirlDesk-FIELD"
ln -sfn "$FIELD/gtk/settings.ini" "$HOME/.config/gtk-3.0/settings.ini"
ln -sfn "$FIELD/gtk/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"
ln -sfn "$FIELD/gtk/gtk-3.css" "$HOME/.config/gtk-3.0/gtk.css"
ln -sfn "$FIELD/gtk/gtk-4.css" "$HOME/.config/gtk-4.0/gtk.css"
ln -sfn "$FIELD/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
ln -sfn "$FIELD/starship/starship.toml" "$HOME/.config/starship.toml"
ln -sfn "$FIELD/waybar/config" "$HOME/.config/waybar/config"
ln -sfn "$FIELD/waybar/style.css" "$HOME/.config/waybar/style.css"
ln -sfn "$FIELD/fuzzel/fuzzel.ini" "$HOME/.config/fuzzel/fuzzel.ini"
ln -sfn "$FIELD/dunst/dunstrc" "$HOME/.config/dunst/dunstrc"
ln -sfn "$FIELD/hyprlock/hyprlock.conf" "$HOME/.config/hypr/hyprlock.conf"

gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme 'SwirlDesk-FIELD' 2>/dev/null || true

profile="$(cat "$ROOT/state/field_wallpaper_profile" 2>/dev/null || echo clean)"
"$ROOT/scripts/field-wallpaper-profile.sh" --quiet --apply "$profile" || true

"$ROOT/scripts/restart-ui.sh"

echo "SwirlDesk FIELD v0.6 active."
echo "Visual profiles: right-click FIELD // in Waybar or use Control Center -> DESKTOP // FIELD visual profile."
