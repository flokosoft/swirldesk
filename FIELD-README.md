# SwirlDesk FIELD 1.0

FIELD is the tactical/rugged workstation profile for SwirlDesk. The design is
built around graphite surfaces, Coyote/Khaki accents, subtle topo/AOR1/MultiCam
backgrounds, and restrained instrument-style system information.

## Daily controls

| Shortcut | Action |
|---|---|
| `SUPER + SPACE` | FIELD CONTROL, centered |
| `SUPER + I` | FIELD STATUS, upper-right |
| `SUPER + CTRL + P` | FIELD POWER, centered |
| `SUPER + L` | FIELD AUTH / Hyprlock |

## Install / upgrade

Extract the release over the existing SwirlDesk directory:

```bash
tar -xzf swirldesk-field-v1.0.tar.gz -C ~/.config/swirldesk
~/.config/swirldesk/scripts/field-v1-activate.sh
```

The activator validates FIELD before reloading Hyprland. Runtime state under
`~/.config/swirldesk/state/` and the active monitor profile under
`~/.local/state/swirldesk/` are not shipped in the release and are not reset.

## Dependencies

Core FIELD assumes the normal SwirlDesk stack. The native panels require GTK3
PyGObject (`python3-gi`, `gir1.2-gtk-3.0`). Useful integration commands include
`jq`, `nmcli`, `wpctl`, `upower`, `dunst`, `waybar`, `fuzzel`, and `kitty`.

Run:

```bash
swirl-field doctor
```

to check the local installation.

## CLI

```text
swirl-field status
swirl-field control
swirl-field power
swirl-field profile clean
swirl-field profile aor1
swirl-field profile multicam
swirl-field check
swirl-field doctor
swirl-field restart
swirl-field version
```

## Visual profiles

- `clean` — dark topo minimal
- `aor1` — Coyote/Khaki desert digital ghost
- `multicam` — subdued organic Coyote/Khaki/Olive ghost

Camouflage remains a low-contrast background texture; application chrome stays
calm and work-focused.
