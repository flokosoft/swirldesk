# Installation, upgrade and recovery

Use README.md as the command reference. Run the central installer as the desktop user (not sudo); it uses sudo only for optional apt actions. Extract the archive in Downloads or another separate directory. Do not copy release files directly over ~/.config/swirldesk. For the source ZIP use Linux `unzip` (preserves Unix symlinks and permissions); avoid tools that dereference symlinks. `./bin/swirldesk-doctor --source` detects changed contents/types.

## Fresh Debian 13

`./install.sh --fresh` installs dependencies from configured sources and pre-integrated SwirlDesk source. Add `--enable-backports` to explicitly allow the official trixie-backports source; `--plasma` optionally installs KDE packages. Use `--no-packages` only if dependencies are already present. No automatic display manager/PAM/default shell changes; log into Hyprland yourself, install JetBrainsMono Nerd Font separately and ensure ~/.local/bin in PATH. Debian theme is initial default. Select MATRIX/FIELD via Super+Shift+T. No old enable scripts are needed. Optional packages may be unavailable, inspect warnings. Real fresh APT path remains untested. Optional Plasma is a separate session: activate via `swirldesk-plasma field` (confirmation, panel/shortcuts changed) or `swirldesk-plasma matrix`; MATRIX preserves current panel and is not a vanilla-panel builder. Restore MATRIX before applying FIELD. Greeter/KVM addons explicitly opt-in.

## Upgrade and verification

Back up current Git checkout **and local configuration** (separately, securely). Close SwirlDesk settings windows. Run from the extracted release:

```
./install.sh --upgrade --no-packages --dry-run
./install.sh --upgrade --no-packages
```

Run second command only if dry run succeeded. KEEP means protected local files; KEEP ALIAS means verified safe historical FIELD alias, not a conflict. RC2 preserves a regular local package list even if release list differs. A changed canonical SVG, external/broken symlink or unknown managed file must remain a conflict. Compare source/installed files and history, merge deliberately, do not delete conflicts to bypass the guard. Use `swirldesk-doctor` after upgrade; reselect theme or start a fresh session only if appropriate. Doctor inventories source plus local retained state; it is not a repair tool or live graphical test.

## Personal backup scope (not for public GitHub)

- ~/.config/swirldesk/state (current theme and visual preferences, MATRIX/Plasma state, potentially machine-specific data); preserve symlinks in a local archive. Back up `hypr/conf`, `hypr/monitors`, `hypr/hypr*.conf`, `zsh/.zshrc`, `packages/debian.txt` and custom files. Also save ~/.local/state/swirldesk, ~/.config/hypr and existing home config links as needed. Backups can contain personal info; keep private and adapt absolute paths when restoring to a different username/machine.
- Plasma: use its existing backup/restore commands; preserve KDE configuration and installed custom plasmoids if needed. `swirl-matrix plasma restore` restores the previous appearance snapshot and resets post-activation managed changes. Do not stack FIELD over active MATRIX. The upgrade does not automatically reapply live QML.
- External settings: VM/libvirt storage and definitions, RDP and VPN credentials, network connections, installed apps, SSH keys, fonts, user files. Maintain separate secure backups, never include them in public release source.

Master source backup is `~/.local/state/swirldesk/master-backups/<timestamp>/` with `changed.json` and previous source files under `files/`; existing home files replaced during fresh link setup may be under `home/`. Source-copy failures roll back that phase. APT, links and wallpaper setup are not a single transaction. For recovery inspect journal, restore old changed files (preserving symlinks), remove newly added files only if unchanged and after review, restore matching manifest/version, and restore personal state if needed. No automated full system rollback is implied. Keep previous release archive and checksums.
