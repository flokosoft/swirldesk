#!/usr/bin/env bash
set -u
ROOT="$HOME/.config/swirldesk"
choice=$(printf '%s\n' '01 // SYSTEM TELEMETRY' '02 // CONSTRUCT' '03 // UPLINK' '04 // VPN TOGGLE' '05 // AUDIO' '06 // THEME' '07 // VISUAL PROFILE' '08 // LOCK' '09 // POWER' | fuzzel --dmenu --prompt 'MATRIX // ' --width 42 --lines 9) || exit 0
case "$choice" in
 '01 // SYSTEM TELEMETRY') exec kitty --class btop-floating -e btop ;;
 '02 // CONSTRUCT') exec "$ROOT/scripts/launcher.sh" ;;
 '03 // UPLINK') exec nm-connection-editor ;;
 '04 // VPN TOGGLE') exec "$ROOT/scripts/wireguard-toggle.sh" ;;
 '05 // AUDIO') exec pavucontrol ;;
 '06 // THEME') exec "$ROOT/scripts/theme-switcher.sh" ;;
 '07 // VISUAL PROFILE') exec "$ROOT/themes/swirldesk-matrix/visual/profile.sh" ;;
 '08 // LOCK') exec hyprlock ;;
 '09 // POWER') exec "$ROOT/scripts/power-menu.sh" ;;
esac
