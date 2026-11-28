#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"; S="$ROOT/matrix-support"
[[ $(cat "$ROOT/state/current_theme_name" 2>/dev/null || true) != swirldesk-matrix ]] || { echo 'Switch to another theme first.' >&2; exit 1; }
(cd "$ROOT" && sha256sum --status -c "$S/session-config.sha256") || { echo 'Configuration changed; refusing rollback.' >&2; exit 1; }
[[ -s "$S/pre-session/themes/swirldesk-matrix/theme.conf" ]] || exit 1
[[ -s "$S/pre-session/themes/swirldesk-matrix/hypr/appearance.conf" ]] || exit 1
[[ -s "$S/pre-session/themes/swirldesk-matrix/hyprlock/hyprlock.conf" ]] || exit 1
[[ -s "$S/pre-session/themes/swirldesk-matrix/waybar/config" ]] || exit 1
[[ -s "$S/pre-session/matrix-support/doctor.sh" ]] || exit 1
bash "$S/disable-session.sh"
cp -p "$S/pre-session/themes/swirldesk-matrix/theme.conf" "$ROOT/themes/swirldesk-matrix/theme.conf"
cp -p "$S/pre-session/themes/swirldesk-matrix/hypr/appearance.conf" "$ROOT/themes/swirldesk-matrix/hypr/appearance.conf"
cp -p "$S/pre-session/themes/swirldesk-matrix/hyprlock/hyprlock.conf" "$ROOT/themes/swirldesk-matrix/hyprlock/hyprlock.conf"
cp -p "$S/pre-session/themes/swirldesk-matrix/waybar/config" "$ROOT/themes/swirldesk-matrix/waybar/config"
cp -p "$S/pre-session/matrix-support/doctor.sh" "$ROOT/matrix-support/doctor.sh"
echo 'MATRIX 0.4.0 config restored. Session assets remain inert.'
