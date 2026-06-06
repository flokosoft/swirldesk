#!/usr/bin/env bash

VPN_NAME="wg0"

if nmcli connection show --active | grep -q "^${VPN_NAME} "; then
    echo '{"text":"󰖂","class":"connected","tooltip":"WireGuard aktiv"}'
else
    echo '{"text":"󰖂","class":"disconnected","tooltip":"WireGuard inaktiv"}'
fi
