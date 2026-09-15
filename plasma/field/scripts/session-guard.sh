#!/usr/bin/env bash
set -u
ROOT="$HOME/.config/swirldesk"
DUNST_CONF="$ROOT/themes/swirldesk-field/dunst/dunstrc"
USER_SYSTEMD="$HOME/.config/systemd/user"
DROPIN="$USER_SYSTEMD/plasma-plasmashell.service.d"
UNIT="$USER_SYSTEMD/swirldesk-field-dunst.service"

case ";${XDG_CURRENT_DESKTOP:-};${XDG_SESSION_DESKTOP:-};" in
  *KDE*|*plasma*) ;;
  *) exit 0 ;;
esac

mkdir -p "$USER_SYSTEMD" "$DROPIN"

# Waybar stays Hyprland-only.
systemctl --user mask --now waybar.service >/dev/null 2>&1 || true
pkill -x waybar 2>/dev/null || true

# Keep the distro Dunst unit out of the way; it may use a default/blue config.
systemctl --user mask --now dunst.service >/dev/null 2>&1 || true

cat > "$UNIT" <<UNIT_EOF
[Unit]
Description=SwirlDesk FIELD notification daemon
Before=plasma-plasmashell.service

[Service]
Type=simple
ExecStart=/usr/bin/dunst --config %h/.config/swirldesk/themes/swirldesk-field/dunst/dunstrc
Restart=on-failure
RestartSec=0.25

[Install]
WantedBy=default.target
UNIT_EOF

cat > "$DROPIN/20-swirldesk-field-notifications.conf" <<'DROPIN_EOF'
[Unit]
Wants=swirldesk-field-dunst.service
After=swirldesk-field-dunst.service
DROPIN_EOF

systemctl --user daemon-reload >/dev/null 2>&1 || true
systemctl --user enable swirldesk-field-dunst.service >/dev/null 2>&1 || true

# For the current session, free the notification name before starting FIELD Dunst.
if pgrep -x plasmashell >/dev/null 2>&1; then
  systemctl --user stop plasma-plasmashell.service >/dev/null 2>&1 || pkill -x plasmashell 2>/dev/null || true
  sleep 0.20
fi
pkill -x dunst 2>/dev/null || true
systemctl --user restart swirldesk-field-dunst.service >/dev/null 2>&1 || \
  dunst --config "$DUNST_CONF" >/dev/null 2>&1 &

# Wait until Dunst really owns org.freedesktop.Notifications.
for _ in $(seq 1 30); do
  owner_pid=""
  if command -v gdbus >/dev/null 2>&1; then
    owner="$(gdbus call --session --dest org.freedesktop.DBus \
      --object-path /org/freedesktop/DBus \
      --method org.freedesktop.DBus.GetNameOwner org.freedesktop.Notifications 2>/dev/null \
      | sed -n "s/.*'\([^']*\)'.*/\1/p")"
    if [[ -n "$owner" ]]; then
      owner_pid="$(gdbus call --session --dest org.freedesktop.DBus \
        --object-path /org/freedesktop/DBus \
        --method org.freedesktop.DBus.GetConnectionUnixProcessID "$owner" 2>/dev/null \
        | sed -nE 's/.*uint32[[:space:]]+([0-9]+).*/\1/p')"
    fi
  fi
  if [[ -n "$owner_pid" ]] && [[ "$(ps -p "$owner_pid" -o comm= 2>/dev/null | xargs)" == dunst ]]; then
    break
  fi
  sleep 0.10
done

systemctl --user start plasma-plasmashell.service >/dev/null 2>&1 || true
exit 0
