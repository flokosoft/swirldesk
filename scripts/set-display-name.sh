#!/usr/bin/env bash

STATE_DIR="$HOME/.config/swirldesk/state"
NAME_FILE="$STATE_DIR/display_name"

mkdir -p "$STATE_DIR"

CURRENT_NAME=""
[ -f "$NAME_FILE" ] && CURRENT_NAME="$(cat "$NAME_FILE")"

NEW_NAME="$(printf "%s\n" "$CURRENT_NAME" | fuzzel --dmenu --prompt 'Anzeigename: ' --width 40 --lines 1 --font 'JetBrainsMono Nerd Font:size=11')"

[ -z "$NEW_NAME" ] && exit 0

printf "%s\n" "$NEW_NAME" > "$NAME_FILE"
notify-send "SwirlDesk" "Anzeigename gesetzt: $NEW_NAME"

