## 0.9.1 TEST — Settings integration
- User confirmed v0.9.0 live operation. Unified GTK3 settings with Fuzzel fallback, three effect presets, existing engine dispatch, master Hyprland doctor and reversible controller integration.
- 8 new + 20 regression unit test methods passed; native GTK/Wayland live test pending. See settings/README.md.
- No new global configuration, authentication, fonts or power daemon. Next: consolidated master installation.

## 0.9.0 TEST — Digital Session
- User confirmed v0.8.2 CRT shader compatibility fix in live use.
- Optional per-session intro, idle rain visualization, logout animation and original local sound; independent existing lock/power policy.
- Screensaver off by default, AC only, 60/180/300s via swayidle. Intro/exit on, sound off. No login manager or shared configuration changes.
- Guarded apply/reapply/rollback and 9 policy, 6 CRT, 5 rain tests passed; actual graphics and idle transitions pending. See digital-session/README.md.

## 0.8.2 TEST — 2026-11-28
- User live test of 0.8.1 exposed shader link error: all shaders must use same shading language version.
- Converted all three CRT fragment shaders from implicit GLSL ES 1.00 to explicit 3.00, matching modern Hyprland screen shader interface. Effect coefficients unchanged.
- All three compile and link with an ES 3.0 test vertex shader via Mesa/EGL; all six CRT logic tests passed. Actual Hyprland version and live compositor rendering not verified.
- Overlay only; no controller, profile, rain, other theme or fonts changes. Turn CRT off before extraction, then select desired mode again.

# MATRIX changelog

## 0.8.1 TEST — CRT / Phosphor
- User confirmed Digital Rain v0.8.0 working. Add optional soft/classic/strong static full-output legacy Hyprland screen shaders; OFF by default.
- AC-only; independent of visual profile/rain; preserve foreign shaders, reversible exact profile integration, no common config changes.
- Six new test methods and five rain regression methods passed; shell syntax checked. Actual GLSL compile attempt blocked by missing libGLESv2; native compositor/GPU test pending. See crt/README.md.

## 0.8.0 TEST — Digital Rain (Hyprland)
- User confirmed 0.7.1 scrollbar fix. Add opt-in CODE RAIN LIVE at 12 FPS target using a local GTK3 Wayland layer surface. Static swaybg is retained, no bundled fonts or media.
- AC-only, fail closed on unknown power; poll every second, destroy surfaces on battery, return automatically on mains. Exit renderer on theme/profile/custom wallpaper change or explicit disable.
- Guarded profile script integration; existing Waybar polling requests restart after login when opted in. No common scripts, Plasma, GTK globally, digital appearance files or other themes changed.
- Five rain test methods, four visual regression methods, lock inheritance check, syntax and archive verification; native Wayland rendering, input passthrough, real AC/docking behavior and resource use not verified. See rain/README.md.

## 0.7.1 TEST — Console scrollbar fix
- User reported vertical scrollbar covering right-aligned values in the Hyprland Control Center. Disable GTK3 overlay scrolling locally and reserve 12 logical pixels at the content end.
- Accept known 0.7.0 file hash when upgrading; original pre-digital rollback remains intact. No changes to actions, telemetry, CSS, other themes or Plasma.

## 0.7.0 TEST — Digital appearance (Hyprland)
- User requested a clearer departure from FIELD. Inset data strip, centered workspaces, phosphor borders, redesigned console, launcher, prompt and session appearance.
- Guarded 19-file apply/restore, separate manifest doctor, original files included. No changes to shared scripts, wallpapers, icons, Plasma or user state.
- Mocked and static tests passed; native desktop rendering still pending. See digital/README.md.

## 0.6.0 TEST — 2026-11-28
- Added separate Plasma 6 appearance overlay, Plasma icon theme, Konsole, native lock wallpaper, MATRIX session menu and Fuzzel launcher.
- Existing matching FIELD label/pager QML receive reversible visual adapters; no panel recreation or shortcut re-registration. Standalone MATRIX widgets included.
- Direct Signal/Bitwarden SVG masks derived from FIELD 0.9.3.7, gated by Plasma version and existing delegate identity.
- Backup and rollback of managed Plasma appearance paths; profile state separate from Hyprland. No fonts, package installation, root access, PAM or session-manager changes.
- 11 isolated automated tests passed; actual Plasma/QML rendering, KDE colors and live power/lock actions remain untested. v0.5.0 explicitly live-tested status not established.

## 0.5.0 TEST — 2026-11-28
- User confirmed v0.4.0 appearance. Added local GTK/Fuzzel session control, confirmed power actions and dark Hyprlock refinement.
- Added local MATRIX Fastfetch report and guarded shared dispatchers; no changes to login manager/PAM, common keybindings, profiles, other themes or Plasma.
- Added guarded 0.5 rollback and session doctor. Native session live tests pending.

## 0.4.0 TEST — 2026-11-28
- Added green SVG icon overlay for application, place, device, file and selected status icon names; fallback inheritance preserved.
- Enabled Fuzzel application icons and GTK icon theme; guarded reversible GSettings sync on MATRIX entry/exit.
- Added best-effort newer Waybar tray mappings and read-only SNI diagnosis; Debian 13 stock Waybar cannot force pixmap replacement.
- No fonts, other theme asset changes, Plasma changes, wallpaper changes or new daemons.
- Native desktop rendering and tray behavior pending live test.

## 0.3.1 TEST — 2026-11-28
- User confirmed v0.3.0 profile functionality; original CONSTRUCT was too bright.
- Replaced only CONSTRUCT wallpaper with muted sage-grey gradient, darker edges and subtle perspective floor.
- Mean sRGB-derived relative luminance reduced from 0.8194 to 0.2961 (about 64%); not a measurement of display brightness.
- CLEAN regenerated byte-identically; CODE RAIN, profile logic, UI, theme-switcher and all other themes untouched.
- Four existing visual regression groups passed; actual desktop appearance pending.

## 0.3.0 TEST — 2026-11-28
- Added static CLEAN, CODE RAIN and CONSTRUCT visual profiles with persistent selection.
- Added Waybar VIS selector, Control Center and Fuzzel fallback integration.
- Guarded reversible automatic theme-switcher integration; preserved prior wallpaper restoration.
- No fonts, animation, other themes or shared Hyprland/Plasma changes.
- Eight test groups passed; native desktop live test pending.

## 0.2.0 TEST — 2026-11-28
- User subsequently confirmed visual test successful.
- Added native GTK3 operator window with local telemetry and existing command shortcuts.
- Waybar MATRIX, CPU and MEM clicks open the console; optional guarded Super+Space dispatcher.
- MATRIX-only floating/center window rule; no common Hyprland config replacement.
- Added Fuzzel fallback, expanded doctor, telemetry tests and reversible dispatcher installation.
- No fonts, wallpaper changes, Plasma changes or changes to the other themes.
- Pending: native GTK and Hyprland live test on user's system.

## 0.1.0 TEST
- Initial Hyprland MATRIX theme; user confirmed first test successful.
