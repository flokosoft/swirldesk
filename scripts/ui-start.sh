#!/usr/bin/env bash
set -u

# SwirlDesk FIELD // fast visible session startup
#
# The old startup serialized Dunst -> Waybar -> wallpaper. That was robust,
# but it also meant the desktop stayed visually empty while Dunst completed
# its D-Bus ownership checks. Dunst startup is now detached from the visible
# shell: it still enforces the exact FIELD config, while Waybar and wallpaper
# can appear immediately.

ROOT="$HOME/.config/swirldesk"

# Start the exact FIELD notification daemon first, but do not make the desktop
# wait for its D-Bus verification loop. notification-status.sh uses
# NameHasOwner before dunstctl, so Waybar will not auto-activate default Dunst.
"$ROOT/scripts/dunst-start.sh" >/dev/null 2>&1 &

# Bring up the visible desktop immediately.
"$ROOT/scripts/wallpaper-restore.sh" >/dev/null 2>&1 &

pkill -x waybar 2>/dev/null || true
waybar &
