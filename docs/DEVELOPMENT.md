# Developer map and release workflow

## Entry points

| Path | Responsibility |
|---|---|
| install.sh, master/install.py, master/manifest.json | source integrity, preflight, preserved configuration, known historical signatures, backup and links |
| bin/swirldesk-doctor, master/doctor.py | read-only release/installed inventory; --source for pristine checkout |
| hypr/hyprland.conf, hypr/conf/*, hypr/monitors/* | shared compositor includes, input, keybinds, rules, startup, machine profiles |
| scripts/theme-switcher.sh | active theme symlink, GTK/Kitty/Fuzzel/Waybar links, wallpaper & theme transition |
| scripts/control-center.sh, scripts/power-menu.sh, bin/swirlfetch | shared dispatch to theme-specific functionality |
| scripts/wallpaper-restore.sh, scripts/ui-start.sh | session startup/visual restoration |
| themes/swirldesk-{debian,graphite,field,matrix}/ | theme.conf, hypr/colors/appearance/cursor, waybar, fuzzel, dunst, kitty, GTK, optional lock/prompt/icons |
| themes/swirldesk-matrix/control/{matrix_operator.py,telemetry.py,operator.css,open.sh} | local GTK3 operator window, data reads and Fuzzel fallback; scrollbar fix in operator window |
| themes/swirldesk-matrix/visual/profile.sh | profile selection and restoration; integration point for effects |
| themes/swirldesk-matrix/visual/rain/{ctl.sh,policy.py,renderer.py} | scoped Wayland background, static fallback, AC gating, 12 FPS target |
| themes/swirldesk-matrix/visual/crt/{ctl.sh,controller.py,*.frag} | Hyprland screen shader, scoped worker, foreign shader guard, ES 3.00 |
| themes/swirldesk-matrix/session/digital/{controller.py,effect.py,ctl.sh,profile-status.sh,connect.wav} | session intro, exit, idle visuals, optional generated sound and runtime gating |
| themes/swirldesk-matrix/settings/settings.py | settings GUI, Fuzzel fallback and existing engine dispatch; presets ECO/BALANCED/IMMERSIVE |
| themes/swirldesk-matrix/session/ | local power confirmation, Fastfetch, lock delegation |
| plasma/field/scripts/{interaction-apply.sh,field-workspaces-de.js,field-workspaces-load.sh,app-icons-apply.sh,app-icons-doctor.sh} | persistent German-layout move+follow, KGlobalAccel release, SNI tray QML and icon diagnostics |
| plasma/matrix/manage.py, plasma/matrix/{compat,tray,style,session,konsole} | distinct KDE palette, profile and reversible appearance overlay |
| bin/swirl-field, bin/swirl-matrix, bin/swirldesk-plasma | KDE entry points (explicit session activation) |
| matrix-support/ | historical overlays/guarded managers, diagnostics, tests; not normal master installation steps |
| addons/kvm_windows11/ | optional VM addon, external host-specific setup |

Legacy non-theme directories under themes/ are retained; only the four named themes are complete supported environments. Additive theme development should preserve shared input/routing and local overrides. Do not rename or change common state lightly. Hyprland active name/link: `state/current_theme_name`, `state/current_theme`; `state/current_wallpaper`, `state/matrix_visual_profile`, `state/matrix_rain_enabled`, `state/matrix_crt_mode`, `state/matrix_digital_session.json`. Session workers are scoped to compositor/Wayland via XDG_RUNTIME_DIR, not system-wide services. The CRT and rain controls gate on actual active MATRIX theme and external power. Settings uses existing controllers, not a second power policy.

## Prior bugs and regression checks

- Plasma German `Meta+Shift+2` produces `Meta+"`; stale FIELD test action occupied it. Runtime KGlobalAccel release before KWin re-registration, also resolves PowerDevil `Meta+B`. Keep verified engine; don't edit only kglobalshortcutsrc and assume live state changed.
- FIELD Plasma tray: icons were installed but actual QML delegate was not. 0.9.3.7 uses known Plasma 6.3.5 direct delegate, local SVGs and masks; verify live identity and version before replacement. MATRIX uses guarded adaptation. Waybar 0.12 limitations are different and unresolved.
- CONSTRUCT too bright: soft sage-grey asset replaced original. Scrollbar covered right-aligned values: disable GTK overlay scrolling and reserve 12px. Keep this local to operator window.
- CRT 0.8.1 used GLSL ES 1.00; Hyprland shader link error fixed in 0.8.2 with ES 3.00. Preserve version and shader interface; compile/link all variants if changed. No artificial flicker. Never override foreign shaders.
- RC1 25 conflicts: 24 FIELD aliases + local package list. RC2 explicit relative alias map and matching SHA256; reject external, broken or changed links. Never loosen conflict policy globally.

## Tests and releases

From clean tree (not live config), set `PYTHONDONTWRITEBYTECODE=1`. Run `python3 matrix-support/rain/tests/test_rain.py`, `python3 matrix-support/crt/tests/test_crt.py`, `python3 matrix-support/digital-session/tests/test_session.py`, `python3 matrix-support/settings/tests/test_settings.py` separately. `python3 master/test_rc2.py` runs disposable HOME and must be unprivileged. Historical tests for older overlay managers may target their specific files and not current consolidated state. Never run real power commands during automated tests. Run shell syntax checks and Python AST parse; validate JSON/GLSL when affected. Master doctor is inventory only; separately run `bash ~/.config/swirldesk/matrix-support/master-doctor.sh` in Hyprland and Plasma component doctors in Plasma. Older textual doctors may return zero despite warnings; inspect output.

For next release (e.g. 1.1.0): work in a separate clean Git checkout, review changes and preserve public/private boundaries. Update VERSION, README, HANDOFF, PROJECT_STATE, DECISIONS, CHANGELOG, VALIDATION and RELEASE_NOTES; use `python3 master/update_manifest.py` after edits (only adds new explicitly approved files via `--add PATH`; never run on installed tree). It retains previous and new signatures for upgrades. Review changes; source doctor; run isolated fresh + upgrade + conflict + regression tests and document results. Build tar.gz and ZIP with Unix symlinks/modes preserved; verify parity and SHA256. Use Git tag and release notes after user validation, not an automatic push. For v1.0.0 no modification of RC2 installer or visual files was necessary. No font files or private data in packages.
