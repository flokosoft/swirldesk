#!/usr/bin/env bash
set -u

# FIELD session UI startup is intentionally serialized:
# 1) exact themed Dunst owns org.freedesktop.Notifications
# 2) Waybar starts
# 3) wallpaper is restored
# This prevents an early D-Bus activated default Dunst from surviving login.

if ! "$HOME/.config/swirldesk/scripts/dunst-start.sh"; then
    printf '[FIELD] notification service did not initialize; continuing UI startup\n' >&2
fi

pkill -x waybar 2>/dev/null || true
waybar &

"$HOME/.config/swirldesk/scripts/wallpaper-restore.sh" &
