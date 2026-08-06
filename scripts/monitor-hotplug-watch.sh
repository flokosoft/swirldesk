#!/usr/bin/env bash

set -u

SCRIPT="$HOME/.config/swirldesk/scripts/lid-monitor.sh"
SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

socat -U - UNIX-CONNECT:"$SOCKET" |
while IFS= read -r event; do
    case "$event" in
        monitoradded*|monitoraddedv2*)
            "$SCRIPT" sync
            ;;
    esac
done
