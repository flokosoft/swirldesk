# SwirlDesk 1.0.0 — Master

Debian 13 · Hyprland · optional KDE Plasma 6. Themes: Debian, Graphite, FIELD and MATRIX. The full MATRIX chain through 0.9.1 and FIELD Plasma 0.9.3.7 is already integrated. No historical enable scripts are needed. Font files are deliberately not shipped. Final consolidated release based on RC2. The user confirmed the RC2 dry-run and live upgrade on the ThinkPad; real fresh Debian/APT and bundled Plasma activation are still unverified. No theme or installer behavior changes since RC2.

## Fresh installation

Extract the archive into a separate directory (e.g. Downloads) or clone the clean source repository. Run as the normal desktop user, **not** with sudo:

```bash
cd swirldesk-1.0.0
./install.sh --fresh
```

This copies the source into `~/.config/swirldesk`, installs packages via sudo apt using configured Debian sources, creates the user links, copies missing wallpapers and initializes Debian as the default theme. For KDE packages too, add `--plasma`. If all dependencies are already present, use `--no-packages`. The configuration uses the Hyprland 0.53+ Hyprlang window-rule syntax. If official Debian 13 backports are missing, the installer refuses an incompatible package candidate; `--enable-backports` explicitly allows it to add the official Debian 13 source. By default apt sources are not changed. The source is compatible with the user's tested modern Hyprland configuration, not guaranteed compatible with older Debian Hyprland versions. JetBrainsMono Nerd Font must be separately installed. Log into Hyprland and select MATRIX or FIELD via Super+Shift+T. Ensure `~/.local/bin` is on PATH. The installer does not change login manager, PAM, default shell, or restart the session.

## Upgrade (recommended for the existing installation)

Extract into a **separate directory**, never directly over the running repository. Close settings windows. Keep your GitHub backup and also back up local state (it is not tracked). Then:

```bash
./install.sh --upgrade --no-packages --dry-run
./install.sh --upgrade --no-packages
```

Remove `--no-packages` only if you explicitly want to check/install/upgrade packages. Dry run is read-only. Unknown changed project files cause a preflight conflict; reconcile them manually, never force overwrite. Existing Hyprland keybindings, monitor profiles, idle settings, shell config, current theme, saved preferences, backups, Git metadata and existing home configuration links are retained. The installer updates known released versions, adds missing files, does not delete obsolete files, and writes a timestamped backup of changed source files plus a changed-file journal to `~/.local/state/swirldesk/master-backups/`. A source-copy error triggers rollback of that copy phase. Apt, later link setup and other user-directory changes are not a single transaction. Use a fresh shell and reselect the active theme after upgrade. For a live Plasma session keep its installed working QML until you explicitly reapply the relevant theme. No automatic apply or restart.

## Plasma activation (optional)

Plasma and Hyprland are separate sessions. In Plasma use `swirldesk-plasma matrix` or `swirl-matrix plasma apply` for MATRIX (restore with `swirl-matrix plasma restore`). MATRIX appearance preserves the existing panel; the tested FIELD-derived layout is not automatically built on vanilla Plasma. To set up the full FIELD layout from scratch, run `swirldesk-plasma field` in KDE (confirmation required). It runs the historical FIELD commands below. This changes Plasma panel and KWin shortcuts; review the backup and existing personal layout first. Do not apply FIELD over active MATRIX without restoring MATRIX. Existing FIELD users do not need to reapply it just to upgrade source.

```bash
swirl-field plasma backup
swirl-field plasma apply
swirl-field plasma panel apply
swirl-field plasma interaction apply
swirl-field plasma window apply
swirl-field plasma shell apply
swirl-field plasma visual apply
swirl-field plasma dolphin apply
swirl-field plasma icons apply
```

MATRIX `swirl-matrix plasma doctor`; FIELD `swirl-field plasma interaction doctor` and `swirl-field plasma icons doctor`. FIELD SNI replacement is based on Plasma 6.3.5; newer versions need verification. KDE package install is optional and not a display-manager setup.

## MATRIX controls

Super+Space opens the operator center; digital session opens unified Settings; Super+Shift+T changes theme. CLEAN, CODE RAIN, Soft CONSTRUCT and CODE RAIN LIVE are included. CRT modes and automated idle saver obey AC gating. The screensaver is **not** a lock; Hyprlock remains the real authentication mechanism. Super+L locks. `bash ~/.config/swirldesk/matrix-support/master-doctor.sh` runs component diagnostics; inspect individual textual MISMATCH lines. Waybar 0.12 can still show colorful app-provided tray pixmaps. Plasma diagnosis is separate.

## Global diagnostics

```bash
swirldesk-doctor
```

This read-only inventory checks the installed manifest, protected local configuration, verified FIELD aliases and active Hyprland theme state; it lists available commands without starting any process or effect. Exit 1 indicates an inventory/state mismatch, not necessarily a broken desktop. For the pristine checkout: `./bin/swirldesk-doctor --source`. For live MATRIX/Plasma checks use the component doctors described above. See `docs/VALIDATION.md` for the precise validation scope.

## GitHub and portability

Use the source ZIP or extract this source tree into a **separate** checkout for review and commit. No `.git`, fonts, personal runtime state, generated backups, actual VM credentials or private keys are packaged. Old rollback scripts/templates remain as development history, not master upgrade commands; do not run old enable/disable scripts on the integrated master. Monitor profiles for a fresh machine are generic; existing ones are protected. The KVM addon and FIELD greetd setup remain explicit opt-in operations, not part of master installation. The VM, RDP secret, VPN connection, display manager, and user-specific system settings are external to this release. Review wallpaper asset rights before publishing publicly; no new license is asserted for the original archive. See `docs/HANDOFF.md` and `docs/PROJECT_STATE.md`.

For a later development session, provide the clean source ZIP or a GitHub checkout and start with `docs/HANDOFF.md`. Detailed code map, regression/release workflow and backup guidance: `docs/DEVELOPMENT.md`, `docs/INSTALLATION.md`.
