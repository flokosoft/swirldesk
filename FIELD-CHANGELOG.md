# SwirlDesk FIELD 1.2

Stability and boot/session integration release.

## Fixed

- FIELD GREET now uses Debian 13's `_greetd` service account instead of the
  generic `greeter` account.
- FIELD GREET defaults to VT7, matching Debian's greetd layout and avoiding the
  normal login console.
- tuigreet remember-cache ownership is prepared for `_greetd`.
- Nextcloud Desktop autostart no longer opens a large tiled window at login.
  It now starts through `nextcloud-start.sh` using `nextcloud --background`.
- Nextcloud startup waits briefly for the tray and refuses to spawn a duplicate
  client if another mechanism already started it.

## Improved

- `swirl-field doctor` checks greetd account/config integration and the
  Nextcloud background-autostart wrapper.
- FIELD preflight includes the UI startup and Nextcloud wrapper scripts.
- Release metadata and CLI version updated to 1.2.

## Preserved

- FIELD CONTROL remains centered.
- FIELD STATUS remains upper-right and updates values without full-window
  redraw/flicker.
- FIELD POWER and FIELD KEYMAP remain centered.
- Coyote/Khaki notification theme and NTF state handling are unchanged.
- CLEAN, AOR1 and MultiCam visual profiles are unchanged.
- No font files are included.
