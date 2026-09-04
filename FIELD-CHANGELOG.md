# SwirlDesk FIELD 1.2.1 // Fast startup hotfix

- Visible session startup is no longer serialized behind Dunst D-Bus checks.
- Waybar and the wallpaper are launched immediately after Hyprland starts.
- The exact FIELD Dunst still starts first, but its verification continues in the background.
- Reduced the deliberate Dunst session-bus settle delay from 350 ms to 50 ms.
- Keeps the v1.2 notification safeguards: Waybar checks NameHasOwner before using dunstctl, so it does not auto-activate default-blue Dunst.
- Nextcloud remains independent and continues waiting for the tray in the background; it does not block the desktop.
