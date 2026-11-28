#!/usr/bin/env bash
set -euo pipefail
D=$(cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(cd "$D/../../../.." && pwd)
STATE="$ROOT/state"; PREF="$STATE/matrix_rain_enabled"
mode=${1:-status}
# Scope lock/status to this compositor, not a simultaneous Plasma or Hyprland session.
valid_session() { [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} && -n ${WAYLAND_DISPLAY:-} && -n ${XDG_RUNTIME_DIR:-} && -d $XDG_RUNTIME_DIR ]]; }
if valid_session; then
    session=$(printf '%s\n' "$HYPRLAND_INSTANCE_SIGNATURE" "$WAYLAND_DISPLAY" | sha256sum | cut -c1-24)
    RUN="$XDG_RUNTIME_DIR/swirldesk-matrix-rain-$session"
fi
pref() { cat "$PREF" 2>/dev/null || true; }
case "$mode" in
 on|off)
    mkdir -p "$STATE"; tmp=$(mktemp "$STATE/.matrix-rain.XXXXXX"); printf '%s\n' "$mode" > "$tmp"; mv -f "$tmp" "$PREF"
    [[ $mode == off ]] || "$D/ctl.sh" kick
    ;;
 kick)
    [[ $(pref) == on ]] || exit 0
    valid_session || exit 0
    [[ $(cat "$STATE/current_theme_name" 2>/dev/null || true) == swirldesk-matrix && $(readlink -f "$STATE/current_theme" 2>/dev/null || true) == "$ROOT/themes/swirldesk-matrix" && $(cat "$STATE/matrix_visual_profile" 2>/dev/null || echo code-rain) == code-rain && $(cat "$STATE/current_wallpaper" 2>/dev/null || true) == "$ROOT/themes/swirldesk-matrix/wallpapers/matrix-code.png" ]] || exit 0
    mkdir -m 700 -p "$RUN"
    exec 8>"$RUN/lock"
    flock -n 8 || exit 0
    now=$(date +%s); prev=$(cat "$RUN/attempt" 2>/dev/null || echo 0)
    # Retry a missing dependency or failed backend no more than once every 20 s.
    if [[ $prev =~ ^[0-9]+$ ]] && (( now >= prev && now - prev < 20 )) && [[ $(cat "$RUN/status" 2>/dev/null || true) != inactive ]]; then exit 0; fi
    printf '%s\n' "$now" > "$RUN/attempt"
    printf 'starting\n' > "$RUN/status"
    nohup env GDK_BACKEND=wayland /usr/bin/python3 "$D/renderer.py" "$RUN/status" </dev/null >"$RUN/log" 2>&1 8>&8 9>&- &
    ;;
 status)
    printf 'Digital rain preference: %s\n' "$( [[ $(pref) == on ]] && echo on || echo off )"
    if valid_session && [[ -d $RUN ]]; then
        exec 8>"$RUN/lock"
        if flock -n 8; then echo 'Renderer: stopped'; else printf 'Renderer: %s\n' "$(cat "$RUN/status" 2>/dev/null || echo starting)"; fi
        [[ ! -s $RUN/log ]] || { echo 'Renderer log (last 5 lines):'; tail -5 "$RUN/log"; }
    else echo 'Renderer: no active runtime state'; fi
    ;;
 doctor)
    /usr/bin/python3 "$D/renderer.py" --check || true
    "$D/ctl.sh" status
    ;;
 *) echo 'Usage: ctl.sh on|off|kick|status|doctor' >&2; exit 2;;
esac
