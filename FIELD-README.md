# SwirlDesk FIELD 1.2

FIELD is the tactical/rugged workstation profile for SwirlDesk: graphite
surfaces, Coyote/Khaki accents, restrained instrument-style UI, and subtle
Topo/AOR1/MultiCam background profiles. It is designed to remain practical as
a daily Debian + Hyprland desktop.

## Daily controls

| Shortcut | Action |
|---|---|
| `SUPER + SPACE` | FIELD CONTROL, centered |
| `SUPER + I` | FIELD STATUS, upper-right, live without full redraw |
| `SUPER + CTRL + P` | FIELD POWER, centered |
| `SUPER + SHIFT + F1` | FIELD KEYMAP, centered |
| `SUPER + L` | FIELD AUTH / Hyprlock |
| `PRINT` | Select screenshot area |
| `SUPER + PRINT` | Screenshot active window |
| `CTRL + PRINT` | Screenshot full desktop |

## Install / upgrade

Extract the release over the existing SwirlDesk directory:

```bash
tar -xzf swirldesk-field-v1.2.tar.gz -C ~/.config/swirldesk
~/.config/swirldesk/scripts/field-v12-activate.sh
```

The activator validates FIELD before reloading Hyprland. Runtime state under
`~/.config/swirldesk/state/` and the active monitor profile under
`~/.local/state/swirldesk/` are not shipped and are not reset.

## FIELD 1.2 stability changes

### greetd / tuigreet

The FIELD greeter now follows Debian 13's greetd packaging:

- greeter account: `_greetd`
- FIELD default terminal: VT7
- `tuigreet` remember-cache permissions are prepared for `_greetd`
- the installer never restarts greetd while your graphical session is active
- the existing `/etc/greetd/config.toml` is backed up before FIELD replaces it

Check first:

```bash
swirl-field greet check
```

Install required Debian packages if needed:

```bash
sudo apt install greetd tuigreet kbd
```

Install FIELD GREET:

```bash
swirl-field greet install
```

The installer intentionally does **not** start or restart greetd. Reboot when
you are ready. If recovery is ever required, use another TTY (for example
`Ctrl+Alt+F2`) and run:

```bash
swirl-field greet restore
```

### Nextcloud Desktop

Nextcloud is no longer launched as a normal foreground application. Hyprland
autostart calls:

```text
~/.config/swirldesk/scripts/nextcloud-start.sh
```

The wrapper waits briefly for the StatusNotifier tray, avoids duplicate client
processes, and starts Nextcloud with `--background`. This prevents the client
window from occupying the workspace immediately after login while preserving
the tray client and sync service.

## Diagnostics

Run:

```bash
swirl-field doctor
```

The doctor checks the FIELD theme, Hyprland config, notification bus, GTK3
panels, FIELD greeter integration, and Nextcloud background-autostart wrapper.

## CLI

```text
swirl-field status
swirl-field control
swirl-field power
swirl-field keymap
swirl-field profile clean
swirl-field profile aor1
swirl-field profile multicam
swirl-field greet check
swirl-field greet install
swirl-field greet restore
swirl-field check
swirl-field doctor
swirl-field restart
swirl-field version
```

## Visual profiles

- `clean` — dark topo minimal
- `aor1` — Coyote/Khaki desert digital ghost
- `multicam` — subdued organic Coyote/Khaki/Olive ghost

Camouflage remains deliberately low contrast. Application chrome stays calm,
readable and work-focused.
