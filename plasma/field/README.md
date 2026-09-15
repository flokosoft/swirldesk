# SwirlDesk FIELD // Plasma 0.7

## Identity / launchers

- `META+SPACE` → KRunner (universal search, commands, files)
- `META+CTRL+ENTER` → Plasma Application Launcher / Kickoff (apps only, familiar quick picker)
- `META+ENTER` → Konsole
- `META+E` → Dolphin
- `META+B` → Firefox
- `META+1…6` → workspaces

The FIELD rail launcher now uses a custom Coyote/Khaki glyph instead of KDE's K icon.

## Plasma icon strategy

`SwirlDesk-FIELD-Plasma` overrides FIELD places/devices/launcher icons and inherits Breeze Dark for the rest. This keeps tray/system icons calm and monochrome while preserving recognizable application brand icons.

## Notifications

FIELD // Plasma uses native Plasma notifications. The Plasma accent is pinned to Coyote (`166,138,91`) and a KDE-only guard stops Dunst if it leaked into the Plasma session.

Diagnostics:

```bash
swirl-field plasma doctor
swirl-field plasma shell doctor
```

Apply/update:

```bash
swirl-field plasma apply
swirl-field plasma panel apply
swirl-field plasma interaction apply
swirl-field plasma shell apply
```

## 0.8 parity shortcuts

- `META+SHIFT+1..6`: move active window to workspace and follow (native KWin script)
- `META+P`: FIELD // PWR

If notifications are unexpectedly blue, run:

```bash
swirl-field plasma notifications doctor
```

In the intended dual-session setup, `dunst.service` and `waybar.service` are masked for the user. Hyprland FIELD starts both executables directly and is therefore unaffected by the masks.

### Apply 0.8 fixes

```bash
swirl-field plasma apply
swirl-field plasma interaction apply
swirl-field plasma shell apply
```

Then log out of Plasma and log back in once. The KWin workspace script and new KGlobalAccel power component are loaded at session start.

Tests:

```text
META + SHIFT + 1..6  move window + follow
META + P             FIELD // PWR
```
