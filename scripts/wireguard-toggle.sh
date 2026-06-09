#!/usr/bin/env bash

VPN_NAME="mikrotik"

if nmcli connection show --active | grep -q "^${VPN_NAME} "; then
    nmcli connection down "$VPN_NAME"
    notify-send "WireGuard" "VPN deaktiviert"
else
    nmcli connection up "$VPN_NAME"
    notify-send "WireGuard" "VPN aktiviert"
fi
