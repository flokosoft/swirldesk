#!/usr/bin/env bash
set -euo pipefail
CONFIG="$HOME/.config/kvm_windows11/config"
[[ -r "$CONFIG" ]] || { echo "Konfiguration fehlt: $CONFIG" >&2; exit 1; }
# shellcheck source=/dev/null
source "$CONFIG"
for cmd in virsh nc secret-tool sdl-freerdp3 hyprctl; do
  command -v "$cmd" >/dev/null || { echo "Programm fehlt: $cmd" >&2; exit 1; }
done
# Keine zweite FreeRDP-Instanz öffnen, wenn bereits eine existiert.
if hyprctl clients -j 2>/dev/null | grep -q '"class": "sdl-freerdp3"'; then
  hyprctl dispatch workspace "${WORKSPACE:-10}" >/dev/null
  exit 0
fi
if ! LC_ALL=C virsh -c "$CONNECTION" domstate "$VM" | grep -qx running; then
  virsh -c "$CONNECTION" start "$VM"
fi
IP=''
for ((i=0; i<${WAIT_SECONDS:-120}; i+=2)); do
  IP=$(LC_ALL=C virsh -c "$CONNECTION" net-dhcp-leases "$NETWORK" | awk -v mac="$MAC" 'tolower($0) ~ tolower(mac) {split($5,a,"/");print a[1]}' | tail -n1)
  if [[ -n "$IP" ]] && nc -z -w 1 "$IP" 3389 2>/dev/null; then break; fi
  IP=''; sleep 2
done
[[ -n "$IP" ]] || { echo 'RDP nicht erreichbar. Windows-RDP und VM-Netzwerk prüfen.' >&2; exit 1; }
PASSWORD=$(secret-tool lookup application win11-kvm credential rdp) || { echo 'Keyring nicht verfügbar.' >&2; exit 1; }
[[ -n "$PASSWORD" ]] || { echo 'Kein RDP-Passwort gespeichert.' >&2; exit 1; }
hyprctl dispatch workspace "${WORKSPACE:-10}" >/dev/null
# FreeRDP-Argumente werden via stdin statt Prozessargumentliste übergeben.
{
  printf '/v:%s\n' "$IP"
  printf '/u:%s\n' "$RDP_USER"
  printf '/d:%s\n' "$RDP_DOMAIN"
  printf '/p:%s\n' "$PASSWORD"
  printf '/f\n/cert:tofu\n'
} | sdl-freerdp3 /args-from:stdin
unset PASSWORD
