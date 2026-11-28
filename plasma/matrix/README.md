# MATRIX // PLASMA 0.6.0 TEST

## Scope
Standalone Plasma appearance overlay for the user's Debian 13 SwirlDesk tree. Base: uploaded `swirldesk.zip`, cumulative MATRIX overlays v0.1.0–v0.5.0, FIELD Plasma 0.9.3.7 tray delegate present in base. Does not replace FIELD source, Hyprland theme switcher, common keybindings, KWin workspace engine or native login/authentication.

## Install / activate
From a Konsole inside KDE Plasma (not Hyprland, SSH, or a root shell):

```sh
cd ~/.config/swirldesk
tar -xzf ~/Downloads/swirldesk-matrix-v0.6.0-plasma-test.tar.gz
./bin/swirl-matrix plasma apply code-rain
./bin/swirl-matrix plasma doctor
```

The tar archive is an additive overlay; v0.3.1 or later MATRIX wallpapers must already exist. v0.5.0 remains the Hyprland version. Requires standard XDG directories, Python 3, Plasma 6 KDE CLI tools, Qt D-Bus client and systemd-managed `plasma-plasmashell.service`. Does not use sudo. Stop any simultaneous appearance edits and save open work before applying. Plasma shell (not KWin) briefly stops/starts. Existing Konsole/Qt apps may need reopening or a logout/login to pick up colors.

## Controls

```sh
./bin/swirl-matrix plasma profile clean
./bin/swirl-matrix plasma profile code-rain
./bin/swirl-matrix plasma profile construct
./bin/swirl-matrix plasma launcher
./bin/swirl-matrix plasma power
./bin/swirl-matrix plasma restore
```

Power and Construct entries are available via KDE's application menu. Existing FIELD shortcuts are unchanged (including existing FIELD power and launcher shortcuts). MATRIX-specific entries can be manually assigned shortcuts later. Native Plasma logout/restart/shutdown prompts remain in use. Suspend requires confirmation and a verified active screen lock. Authentication is KScreenLocker; no login-manager/PAM changes. Lock wallpaper always uses dark CODE RAIN. Existing FIELD notification daemon/guard is not modified, so notifications can retain their FIELD appearance.

## Panel / tray
Existing FIELD rail layout stays intact. If installed FIELD label/pager QML exactly matches the uploaded source, only their installed local QML files are temporarily adapted to MATRIX. The original source in `plasma/field` stays untouched. Custom QML is left unchanged. If starting with another panel, add the standalone `MATRIX //` and `MATRIX Workspace Rail` widgets manually via Plasma Add Widgets; no panel is automatically created, moved, or deleted. Existing virtual desktop count, placement, rules and shortcuts are not changed.

The Signal/Bitwarden masks derive from the known FIELD 0.9.3.7 template. The delegate is installed only with a known compatible local FIELD delegate on Plasma 6.3.5/6.3.6, or a recognizable stock 6.3.5 tray. Unknown versions/delegates are skipped. The two apps are targeted; other tray icons keep native rendering. The doctor verifies disk files, not actual loaded QML or live app identity. This is not a guarantee of monochrome rendering on all Plasma versions.

## Restore / safety
`restore` restores the snapshot from before MATRIX activation, including prior `kdeglobals`, `plasmarc`, `konsolerc`, `kscreenlockerrc`, `plasma-org.kde.plasma.desktop-appletsrc`, managed user-local tray and applet assets. It briefly stops/starts plasmashell and keeps the backup in `~/.config/swirldesk/backups/plasma-matrix/snapshot-*`. It does NOT restore kwinrc or kglobalshortcutsrc because they are not edited. Appearance and panel changes made AFTER activation are lost on rollback; do not make manual changes you want to keep until after restoring. Restore before applying another Plasma appearance profile, especially FIELD. A failed apply attempts automatic rollback; if that fails the snapshot is retained and `restore` can be retried from Plasma. If the shell does not restart, run `systemctl --user start plasma-plasmashell.service` from an existing terminal. Managed symlink targets and nonstandard XDG locations are refused. No system-installed Plasma files are overwritten.

## Test evidence and handoff
- `python3 plasma/matrix/tests/test_plasma.py` — 11 isolated tests including apply/profile/restore, repeated activation protection, custom widget preservation, compatibility gates, failure rollback, symlink refusal, SVG/XML + metadata, and power confirmation/guard with mocked commands. The tests do not operate on a real Plasma session.
- `bash -n` and Python syntax checked; tar checked after packaging. No native Plasma/QML runtime, GTK rendering, real lock/suspend/logout or real tray behavior tested here.
- Current release v0.6.0 TEST. User positively reported v0.1–0.4 functionality; v0.5 continuation requested but specific live behavior not explicitly confirmed. Next: live tests, especially tray and FIELD restore, notification theming only if needed, then master/handoff archive.
- Design: black #050805, surfaces #0c160f, text #b4dcc1, green #00b950, active #00ff65; JetBrainsMono Nerd Font (not bundled). Existing soft CONSTRUCT wallpaper from v0.3.1 reused. No new fonts or background daemons.
- Source references: KDE Plasma desktop scripting https://develop.kde.org/docs/plasma/scripting/api/ ; KDE native logout prompts https://discuss.kde.org/t/what-command-to-display-the-sddm-shutdown-screen-on-plasma-6/11382 ; Debian Plasma tools https://packages.debian.org/trixie/amd64/plasma-workspace/filelist . Tray derivative retains the original LGPL SPDX attribution.
