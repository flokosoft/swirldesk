#!/usr/bin/env bash
set -u

# SwirlDesk FIELD // deterministic Dunst startup
# Never use dunstctl as a readiness probe here: querying Dunst's private
# control bus during login can itself participate in a D-Bus activation race.

ROOT="$HOME/.config/swirldesk"
CACHE_DIR="$HOME/.cache/swirldesk"
LOG="$CACHE_DIR/dunst.log"
RUNTIME_BASE="${XDG_RUNTIME_DIR:-/tmp}"
STATE_FILE="$RUNTIME_BASE/swirldesk-field-ntf-${UID}.state"
LOCK_FILE="$RUNTIME_BASE/swirldesk-field-dunst-${UID}.lock"
mkdir -p "$CACHE_DIR"

# Serialize startup/restart requests.
exec 9>"$LOCK_FILE"
if command -v flock >/dev/null 2>&1; then
    flock -w 8 9 || exit 1
fi

CONF="$ROOT/state/current_theme/dunst/dunstrc"
if [ ! -r "$CONF" ]; then
    CONF="$ROOT/themes/swirldesk-field/dunst/dunstrc"
fi
if [ ! -r "$CONF" ]; then
    CONF="$HOME/.config/dunst/dunstrc"
fi
if [ ! -r "$CONF" ]; then
    printf '[%s] FIELD ERROR: no readable dunstrc found\n' "$(date -Is)" >> "$LOG"
    exit 1
fi

REAL_CONF="$(readlink -f "$CONF" 2>/dev/null || printf '%s' "$CONF")"
printf '[%s] FIELD dunst config: %s\n' "$(date -Is)" "$REAL_CONF" >> "$LOG"

if ! command -v dunst >/dev/null 2>&1; then
    printf '[%s] FIELD ERROR: dunst binary not found\n' "$(date -Is)" >> "$LOG"
    exit 1
fi

name_has_owner() {
    command -v gdbus >/dev/null 2>&1 || return 1
    local out
    out="$(gdbus call --session \
        --dest org.freedesktop.DBus \
        --object-path /org/freedesktop/DBus \
        --method org.freedesktop.DBus.NameHasOwner \
        org.freedesktop.Notifications 2>/dev/null || true)"
    [[ "$out" == *true* ]]
}

notification_owner_pid() {
    command -v gdbus >/dev/null 2>&1 || return 1
    local owner_raw owner pid_raw pid
    owner_raw="$(gdbus call --session \
        --dest org.freedesktop.DBus \
        --object-path /org/freedesktop/DBus \
        --method org.freedesktop.DBus.GetNameOwner \
        org.freedesktop.Notifications 2>/dev/null || true)"
    owner="$(printf '%s' "$owner_raw" | sed -n "s/^('\([^']*\)',)$/\1/p")"
    [ -n "$owner" ] || return 1

    pid_raw="$(gdbus call --session \
        --dest org.freedesktop.DBus \
        --object-path /org/freedesktop/DBus \
        --method org.freedesktop.DBus.GetConnectionUnixProcessID \
        "$owner" 2>/dev/null || true)"
    pid="$(printf '%s' "$pid_raw" | sed -nE 's/.*uint32[[:space:]]+([0-9]+).*/\1/p')"
    [ -n "$pid" ] || pid="$(printf '%s' "$pid_raw" | grep -oE '[0-9]+' | tail -n1)"
    [ -n "$pid" ] || return 1
    printf '%s\n' "$pid"
}

known_notification_pid() {
    local pid="$1" comm
    [ -r "/proc/$pid/comm" ] || return 1
    comm="$(cat "/proc/$pid/comm" 2>/dev/null || true)"
    case "$comm" in
        dunst|xfce4-notifyd|mako|swaync|notification-daemon) return 0 ;;
    esac
    return 1
}

# Do not deliberately stall the visible login path here. ui-start.sh runs this
# helper asynchronously, and the ownership/retry loops below already handle
# a session bus that is still settling or a competing notifier.
sleep 0.05

for daemon in xfce4-notifyd mako swaync notification-daemon dunst; do
    pkill -x "$daemon" 2>/dev/null || true
done

# Wait until the standard notification name is actually free. NameHasOwner
# does not auto-activate a notification service.
for _ in $(seq 1 30); do
    name_has_owner || break
    owner_pid="$(notification_owner_pid 2>/dev/null || true)"
    if [ -n "$owner_pid" ] && known_notification_pid "$owner_pid"; then
        kill "$owner_pid" 2>/dev/null || true
    fi
    sleep 0.1
done

start_field_dunst() {
    dunst --config "$REAL_CONF" --verbosity info >>"$LOG" 2>&1 &
    DUNST_PID=$!
    printf '[%s] FIELD dunst launched pid=%s\n' "$(date -Is)" "$DUNST_PID" >> "$LOG"
}

start_field_dunst

# Verify ownership using only the standard notification bus. This avoids the
# dunstctl/private-interface race that caused default-blue Dunst after login.
for _ in $(seq 1 80); do
    if name_has_owner; then
        owner_pid="$(notification_owner_pid 2>/dev/null || true)"
        if [ -n "$owner_pid" ] && [ "$owner_pid" = "$DUNST_PID" ]; then
            printf 'running\n' > "$STATE_FILE"
            printf '[%s] FIELD dunst owns org.freedesktop.Notifications pid=%s\n' "$(date -Is)" "$DUNST_PID" >> "$LOG"
            exit 0
        fi

        # A known notifier won the race. Remove it and retry FIELD once the
        # launched process has lost/exited.
        if [ -n "$owner_pid" ] && known_notification_pid "$owner_pid"; then
            printf '[%s] FIELD replacing competing notifier pid=%s\n' "$(date -Is)" "$owner_pid" >> "$LOG"
            kill "$owner_pid" 2>/dev/null || true
            sleep 0.12
            if ! kill -0 "$DUNST_PID" 2>/dev/null; then
                start_field_dunst
            fi
        fi
    elif ! kill -0 "$DUNST_PID" 2>/dev/null; then
        start_field_dunst
    fi
    sleep 0.1
done

printf '[%s] FIELD ERROR: exact Dunst did not acquire notification bus\n' "$(date -Is)" >> "$LOG"
exit 1
