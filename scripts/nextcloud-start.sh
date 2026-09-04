#!/usr/bin/env bash
set -u

# SwirlDesk FIELD: start Nextcloud as a tray/background application.
# A single tiled window in Hyprland fills the workspace, which can look like
# "fullscreen". Starting Nextcloud before Waybar's tray is ready can also make
# the client present its main dialog. Wait briefly for the StatusNotifier tray
# and always use Nextcloud's documented --background mode.

command -v nextcloud >/dev/null 2>&1 || exit 0

# Do not spawn a second client if another autostart mechanism already did.
if pgrep -x nextcloud >/dev/null 2>&1; then
    exit 0
fi

# Wait up to ~5s for Waybar's StatusNotifier watcher. This is best-effort only;
# --background remains the authoritative way to suppress the main dialog.
if command -v gdbus >/dev/null 2>&1; then
    for _ in $(seq 1 20); do
        out=$(gdbus call --session \
            --dest org.freedesktop.DBus \
            --object-path /org/freedesktop/DBus \
            --method org.freedesktop.DBus.NameHasOwner \
            org.kde.StatusNotifierWatcher 2>/dev/null || true)
        [[ "$out" == *true* ]] && break
        sleep 0.25
    done
else
    for _ in $(seq 1 20); do
        pgrep -x waybar >/dev/null 2>&1 && { sleep 0.5; break; }
        sleep 0.25
    done
fi

exec nextcloud --background
