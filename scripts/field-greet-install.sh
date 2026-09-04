#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/greetd"
ETC=/etc/greetd
BACKUP="$ETC/config.toml.pre-swirldesk-field"

usage() {
cat <<'EOF'
SwirlDesk FIELD // GREET

Usage:
  field-greet-install.sh check
  field-greet-install.sh install
  field-greet-install.sh restore

The installer never restarts greetd or logs you out. A reboot is the safest way
to activate or restore the greeter.
EOF
}

need() {
    command -v "$1" >/dev/null 2>&1 && return 0
    [ -x "/usr/sbin/$1" ] && return 0
    return 1
}

check() {
    local fail=0
    printf '%s\n' 'FIELD // GREET CHECK'
    for c in greetd tuigreet setvtrgb; do
        if need "$c"; then printf 'OK      cmd/%s\n' "$c"; else printf 'MISSING cmd/%s\n' "$c"; fail=1; fi
    done
    [ -f "$ETC/config.toml" ] && printf 'OK      %s\n' "$ETC/config.toml" || { printf 'MISSING %s\n' "$ETC/config.toml"; fail=1; }
    getent passwd _greetd >/dev/null 2>&1 && printf 'OK      user/_greetd\n' || { printf 'MISSING user/_greetd\n'; fail=1; }
    if systemctl is-enabled greetd.service >/dev/null 2>&1; then
        printf 'OK      greetd/enabled\n'
    else
        printf 'WARN    greetd/not-enabled\n'
    fi
    if [ -f "$ETC/swirldesk-field-greet" ]; then printf 'OK      field/greet-script\n'; else printf 'INFO    field/not-installed\n'; fi
    return "$fail"
}

install_field() {
    local missing=()
    for c in greetd tuigreet setvtrgb; do need "$c" || missing+=("$c"); done
    if ((${#missing[@]})); then
        printf 'Required commands missing: %s\n' "${missing[*]}" >&2
        printf '%s\n' 'On Debian 13 install them with:' >&2
        printf '%s\n' '  sudo apt install greetd tuigreet kbd' >&2
        exit 2
    fi

    sudo install -d -m 0755 "$ETC"
    if sudo test -f "$ETC/config.toml" && ! sudo test -e "$BACKUP"; then
        sudo cp -a "$ETC/config.toml" "$BACKUP"
        printf 'Backup: %s\n' "$BACKUP"
    fi

    sudo install -m 0755 "$SRC/swirldesk-field-greet" "$ETC/swirldesk-field-greet"
    sudo install -m 0644 "$SRC/field-vt-palette" "$ETC/swirldesk-field-vt-palette"
    sudo install -m 0644 "$SRC/config.toml" "$ETC/config.toml"
    sudo install -m 0755 "$SRC/swirldesk-session" /usr/local/bin/swirldesk-session
    sudo install -d -m 0755 /usr/local/share/wayland-sessions
    sudo install -m 0644 "$SRC/swirldesk-field.desktop" /usr/local/share/wayland-sessions/swirldesk-field.desktop

    # Debian's tuigreet package ships a tmpfiles rule for its remember cache.
    if [ -f /usr/lib/tmpfiles.d/tuigreet.conf ]; then
        sudo systemd-tmpfiles --create /usr/lib/tmpfiles.d/tuigreet.conf >/dev/null 2>&1 || true
    fi
    # Debian's greetd package runs the greeter as _greetd. Ensure tuigreet's
    # remember cache, when present, is writable by that account.
    if getent passwd _greetd >/dev/null 2>&1 && sudo test -d /var/cache/tuigreet; then
        sudo chown _greetd:_greetd /var/cache/tuigreet >/dev/null 2>&1 || true
        sudo chmod 0755 /var/cache/tuigreet >/dev/null 2>&1 || true
    fi

    printf '%s\n' 'FIELD // GREET INSTALLED'
    printf '%s\n' 'No service was restarted; your current graphical session is untouched.'
    if ! systemctl is-enabled greetd.service >/dev/null 2>&1; then
        printf '%s\n' 'NOTE: greetd.service is not enabled. Do not enable it until any other display manager conflict is resolved.'
    fi
    printf '%s\n' 'Reboot when you are ready to test the FIELD greeter.'
    printf '%s\n' 'TTY recovery: Ctrl+Alt+F2, then restore with:'
    printf '  %q restore\n' "$0"
}

restore_field() {
    if ! sudo test -f "$BACKUP"; then
        printf 'No backup found at %s\n' "$BACKUP" >&2
        exit 1
    fi
    sudo cp -a "$BACKUP" "$ETC/config.toml"
    printf '%s\n' 'FIELD // GREET CONFIG RESTORED'
    printf '%s\n' 'No service was restarted. Reboot to use the restored greeter.'
}

case "${1:-check}" in
    check) check ;;
    install) install_field ;;
    restore) restore_field ;;
    -h|--help|help) usage ;;
    *) usage >&2; exit 2 ;;
esac
