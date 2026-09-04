# SwirlDesk FIELD // GREET

FIELD GREET intentionally stays a console/TUI login rather than a graphical
login screen. It uses `greetd` + Debian's `tuigreet` and temporarily remaps the
Linux VT's 16 ANSI colors to the FIELD Coyote/Khaki/Olive palette with
`setvtrgb`. The palette is restored when the greeter exits.

## Result

- black / graphite console
- Coyote border and prompts
- Khaki title and clock
- warm off-white input/text
- remembered username and per-user session
- F3 session selector and F12 power menu remain standard tuigreet behavior
- no wallpaper, mouse UI, blur, avatars or graphical compositor

## Check

```bash
~/.config/swirldesk/scripts/field-greet-install.sh check
```

If commands are missing on Debian 13:

```bash
sudo apt install greetd tuigreet kbd
```

## Install

```bash
~/.config/swirldesk/scripts/field-greet-install.sh install
```

The script backs up an existing `/etc/greetd/config.toml` once as
`/etc/greetd/config.toml.pre-swirldesk-field`. It deliberately does **not**
restart greetd and does not enable a display manager. Reboot when ready.

## Restore

From the desktop or a TTY:

```bash
~/.config/swirldesk/scripts/field-greet-install.sh restore
```

Then reboot.
