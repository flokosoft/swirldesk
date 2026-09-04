#!/usr/bin/env bash
set -u
ROOT="${1:-$HOME/.config/swirldesk/themes/swirldesk-field}"
SWIRL="${ROOT%/themes/swirldesk-field}"
required=(
  hypr/colors.conf
  hypr/appearance.conf
  hypr/cursor.conf
  waybar/config
  waybar/style.css
  dunst/dunstrc
  fuzzel/fuzzel.ini
  kitty/kitty.conf
  gtk/settings.ini
  gtk/gtk-3.css
  hyprlock/hyprlock.conf
  hyprlock/field-background.png
)
wallpapers=(
  field-topo-minimal-1920x1200.png
  field-topo-aor1-ghost-1920x1200.png
  field-topo-multicam-ghost-1920x1200.png
)
scripts=(
  field-waybar-time.sh
  field-waybar-sys.sh
  field-waybar-comms.sh
  field-waybar-power.sh
  field-status.sh
  field-status-toggle.sh
  field-lock-status.sh
  notification-status.sh
  toggle-notifications.sh
  dunst-start.sh
  power-menu.sh
  power-menu-fallback.sh
  field-power-toggle.sh
  field-power.py
  field-doctor.sh
  control-center.sh
  control-center-fallback.sh
  field-control-toggle.sh
  field-control.py
  restart-ui.sh
)
missing=0
for rel in "${required[@]}"; do
    if [ -f "$ROOT/$rel" ]; then
        printf 'OK      %s\n' "$rel"
    else
        printf 'MISSING %s\n' "$rel" >&2
        missing=1
    fi
done
for name in "${wallpapers[@]}"; do
    rel="wallpapers/SwirlDeskFIELD/$name"
    if [ -f "$SWIRL/$rel" ]; then
        printf 'OK      %s\n' "$rel"
    else
        printf 'MISSING %s\n' "$rel" >&2
        missing=1
    fi
done
for script in "${scripts[@]}"; do
    if [ -f "$SWIRL/scripts/$script" ]; then
        printf 'OK      scripts/%s\n' "$script"
    else
        printf 'MISSING scripts/%s\n' "$script" >&2
        missing=1
    fi
done
exit "$missing"
