#!/usr/bin/env bash
set -u
ROOT="$HOME/.config/swirldesk"
FAIL=0

ok(){ printf 'OK      %s\n' "$1"; }
warn(){ printf 'WARN    %s\n' "$1"; }
fail(){ printf 'MISSING %s\n' "$1" >&2; FAIL=1; }

printf 'SwirlDesk FIELD // DOCTOR\n'
printf '%s\n' '----------------------------------------'

for cmd in hyprctl waybar dunst notify-send fuzzel kitty jq python3 nmcli wpctl; do
    command -v "$cmd" >/dev/null 2>&1 && ok "cmd/$cmd" || fail "cmd/$cmd"
done

if python3 - <<'PY' >/dev/null 2>&1
import gi
gi.require_version('Gtk','3.0')
from gi.repository import Gtk
PY
then ok 'python/gtk3'; else fail 'python/gtk3 (python3-gi + gir1.2-gtk-3.0)'; fi

[ -L "$ROOT/state/current_theme" ] && ok 'state/current_theme symlink' || fail 'state/current_theme symlink'
THEME=$(readlink -f "$ROOT/state/current_theme" 2>/dev/null || true)
[ -n "$THEME" ] && [ -d "$THEME" ] && ok "theme/$THEME" || fail 'theme target'

if [ -x "$ROOT/scripts/field-theme-check.sh" ]; then
    "$ROOT/scripts/field-theme-check.sh" "$ROOT/themes/swirldesk-field" || FAIL=1
fi

if command -v hyprctl >/dev/null 2>&1; then
    ERR=$(hyprctl configerrors 2>/dev/null || true)
    if [ -z "$ERR" ]; then ok 'hyprland/config'; else warn "hyprland/configerrors: $ERR"; FAIL=1; fi
fi

if command -v gdbus >/dev/null 2>&1; then
    BUS=$(gdbus call --session --dest org.freedesktop.DBus --object-path /org/freedesktop/DBus --method org.freedesktop.DBus.NameHasOwner org.freedesktop.Notifications 2>/dev/null || true)
    [[ "$BUS" == *true* ]] && ok 'notifications/dbus-owner' || warn 'notifications/no owner'
fi

printf '%s\n' '----------------------------------------'
if (( FAIL )); then
    printf 'FIELD DOCTOR // ATTENTION REQUIRED\n'
    exit 1
fi
printf 'FIELD DOCTOR // READY\n'
