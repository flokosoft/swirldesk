# Project state — 2026-11-28

Version: **1.0.0**, final consolidated baseline of RC2. RC2 live dry-run and actual upgrade confirmed by user. Final additions: read-only master doctor, release tooling and handoff documentation. Installer logic and visual assets unchanged.

| Area | Version / status |
|---|---|
| Debian and Graphite Hyprland | Original integrated themes |
| FIELD Hyprland | v1.2 |
| FIELD Plasma | v0.9.3.7; earlier shortcuts/tray confirmed working |
| MATRIX Hyprland | v0.9.1; development releases accepted, RC2 upgrade confirmed |
| MATRIX Plasma | v0.6.0; development stand accepted, full fresh KDE test open |
| Master installer | RC2 algorithm; final release inventory updated |
| Fonts | External JetBrainsMono Nerd Font |

## Open checks and limits

- Final 1.0.0 live upgrade; real fresh Debian 13 with APT/backports; optional Plasma dependencies and full activation; full monitor/AC/DPMS transitions and runtime doctor output. User feedback on individual releases is not exhaustive test evidence.
- Waybar 0.12 does not reliably override app pixmaps. Plasma tray QML is version sensitive (6.3.5). No global compositor replacement, PAM or login manager changes. Screensaver is not a security lock.
- Personal state, monitor profiles, VPN credentials, VM and RDP secrets, fonts and installed applications outside package list are not restored by source alone. Optional packages may fail and are reported separately. No license for original artwork is asserted.
- Historical per-overlay templates/tests are not all valid against consolidated files. Preserve them as history, not runtime installers. See `DEVELOPMENT.md` for supported tests.
