# Changelog

## 1.0.0 — 2026-11-28
- RC2 dry-run and live upgrade confirmed by user without conflicts. Promote RC2 as final consolidated source baseline.
- Add read-only global `swirldesk-doctor` inventory, release/manifest tooling and detailed handoff, installation, development and validation documentation.
- No changes to the RC2 installer logic, theme files, effects, Plasma implementation or keybindings.
- Fresh real Debian/APT installation and bundled Plasma activation still require live verification.

## 1.0.0-rc2 — 2026-11-28
- Preserve the local regular package list on upgrade; the release package list remains the source for optional dependency installation.
- Recognize 24 explicitly mapped historical FIELD SVG aliases only when the relative symlink resolves to the expected internal canonical regular file and its SHA-256 equals the release SVG. Preserve verified aliases without replacing them. Other conflicts still abort.
- No changes to theme assets or running sessions.

## 1.0.0-rc1 — 2026-11-28
- Consolidated original SwirlDesk and all MATRIX releases through 0.9.1 plus FIELD Plasma 0.9.3.7.
- Added master installer with fresh/upgrade/dry-run, historical fingerprint checks, conflict protection, timestamped file backup and separate optional KDE packages.
- Added portable monitor defaults, sanitized example VM config, portable home paths, Git ignore rules and master handoff.
- No change to integrated MATRIX visuals, effect controls, or FIELD shortcut/QML implementation. Historical changelogs remain at `matrix-support/CHANGELOG.md`, `FIELD-CHANGELOG.md` and `FIELD-PLASMA-CHANGELOG.md`.
