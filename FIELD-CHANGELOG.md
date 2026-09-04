# SwirlDesk FIELD 1.0

Release/polish milestone based on the stable v0.9.x design.

- FIELD CONTROL stays centered (`SUPER+SPACE`).
- FIELD STATUS stays upper-right (`SUPER+I`) and uses selective GTK updates to avoid flicker.
- New native FIELD POWER panel (`SUPER+CTRL+P`) with in-panel confirmation for logout, reboot and shutdown.
- Preserves the Fuzzel power menu as a fallback when GTK3 PyGObject is unavailable or another SwirlDesk theme is active.
- Adds `swirl-field` CLI for control/status/power/profile/check/doctor/restart/version.
- Adds extended `field-doctor.sh` diagnostics.
- Release activator validates the complete FIELD payload before relinking/reloading.
- Runtime state is intentionally not part of the release payload and is preserved during activation.
- Theme metadata bumped to 1.0.
- Theme-switch notification no longer probes Dunst through `dunstctl`, avoiding the earlier Debian/Wayland D-Bus activation race.
- Removes development `__pycache__` and stale version marker files from the release payload.
- No fonts are bundled.
