# SwirlDesk 1.0.0 — authoritative handoff

Stand: 2026-11-28. This is the entry point for a new chat or developer with no prior conversation. The clean source tree in this package is authoritative. The installed ThinkPad may contain additional local changes deliberately excluded from the release. Do not reconstruct from snippets or replay historical overlay packages.

## Start here

1. Read `README.md`, `docs/PROJECT_STATE.md`, `docs/DECISIONS.md`, `docs/DEVELOPMENT.md`, `docs/INSTALLATION.md`, `docs/CHANGELOG.md`, `docs/VALIDATION.md` and `docs/RELEASE_NOTES.md`.
2. Verify release SHA256 externally; extract to a separate directory; run `./bin/swirldesk-doctor --source`. Do not modify the working user's installation to investigate.
3. For live problems request `swirldesk-doctor`, applicable component doctor, actual Hyprland/Plasma/Waybar versions, and relevant local file diffs. Never request secrets. For new releases use the clean checkout as starting point, compare changed files, regenerate manifest retaining known historical signatures, run regression tests and update docs.
4. On an existing installation use the separate release tree's `./install.sh --upgrade --no-packages --dry-run` then `./install.sh --upgrade --no-packages` if conflict-free. No historical enable scripts. Preserve local monitor/keybind/shell settings and runtime state. No force override.

## Architecture and accepted behavior

- Debian 13, modern Hyprland (configuration expects >=0.53 Hyprlang syntax), optional KDE Plasma 6. Four Hyprland themes (`themes/swirldesk-{debian,graphite,field,matrix}`); shared core `hypr/`, `scripts/`, `bin/`. Theme switch via Super+Shift+T, control via Super+Space. Ten Hyprland workspaces; Signal 9, Windows VM 10, presentation intended on 7/8 subject to local configuration. FIELD Plasma has six workspaces, with its separate KWin engine.
- FIELD Hyprland v1.2; FIELD Plasma v0.9.3.7: live-confirmed shortcut conflict resolution and direct Signal/Bitwarden monochrome QML override. Do not reregister or rebuild on routine master upgrades.
- MATRIX Hyprland v0.9.1: digital appearance, scroll fix, CLEAN/CODE RAIN/Soft CONSTRUCT, optional rain, ES 3.00 CRT, intro/exit, idle visualization, local audio, settings/presets. User reported positive live results during development. Screensaver is not authentication; Hypridle/Hyprlock remain authoritative. Effects remain opt-in/AC-gated where implemented.
- MATRIX Plasma v0.6.0: independent palette/profile/restore; user accepted the development stand. Full native KDE activation on clean system still unverified. Do not conflate Hyprland and Plasma state.
- Fonts external: JetBrainsMono Nerd Font; never package font files. Git history, personal runtime state, credentials, generated backups excluded. GitHub source backup is maintained by user; no push performed here.

## Release lineage and status

RC1 consolidated original source + FIELD Plasma 0.9.3.4–0.9.3.7 and MATRIX 0.1.0–0.9.1. RC1 live dry-run caught 24 historical FIELD aliases (regular release copies vs likely live symlinks) and a local package list. RC2 preserves only explicitly mapped content-identical safe aliases and local regular package list. User confirmed RC2 dry-run and actual upgrade successful, no conflicts. Final 1.0.0 promotes that baseline without theme/installer logic changes; adds documentation and inventory doctor. Fresh real Debian APT install, full new Plasma activation, final 1.0.0 upgrade and systematic battery/multimonitor checks remain open. See validation document for prior versus newly executed checks.

## Next work

Recommended: validate final upgrade and fresh Debian 13 VM before broad distribution; then branch for 1.1.0. Keep regressions in mind: German KWin Meta+Shift+2, Meta+B PowerDevil, Plasma tray QML 6.3.5, GTK scrollbar, ES 3.00 shader link, AC and theme exit cleanup. Waybar 0.12 app-owned colored tray pixmaps remain a known limitation; do not silently replace system Waybar. No automatic shader failure recovery beyond existing behavior. Future theme work should be additive; avoid rewriting shared core without a clear need.
