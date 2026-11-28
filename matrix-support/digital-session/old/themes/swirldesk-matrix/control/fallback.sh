#!/usr/bin/env bash
set -u
ROOT="$HOME/.config/swirldesk"
choice=$(printf '%s\n' 'system monitor' 'search applications' 'network settings' 'toggle VPN' 'audio mixer' 'switch theme' 'visual profile' 'lock session' 'session menu' | fuzzel --dmenu --prompt 'console > ' --width 42 --lines 9) || exit 0
case "$choice" in
 'system monitor') exec kitty --class btop-floating -e btop ;;
 'search applications') exec "$ROOT/scripts/launcher.sh" ;;
 'network settings') exec nm-connection-editor ;;
 'toggle VPN') exec "$ROOT/scripts/wireguard-toggle.sh" ;;
 'audio mixer') exec pavucontrol ;;
 'switch theme') exec "$ROOT/scripts/theme-switcher.sh" ;;
 'visual profile') exec "$ROOT/themes/swirldesk-matrix/visual/profile.sh" ;;
 'lock session') exec hyprlock ;;
 'session menu') exec "$ROOT/scripts/power-menu.sh" ;;
esac
