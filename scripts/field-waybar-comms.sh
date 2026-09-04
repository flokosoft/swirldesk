#!/usr/bin/env bash
set -u

iface=$(nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null | awk -F: '$3=="connected" && ($2=="wifi" || $2=="ethernet") {print $1; exit}')

if [ -z "${iface:-}" ]; then
    printf '{"text":"COMMS ○","tooltip":"LINK   OFFLINE","class":"offline"}\n'
    exit 0
fi

type=$(nmcli -g GENERAL.TYPE device show "$iface" 2>/dev/null | head -n1)
conn=$(nmcli -g GENERAL.CONNECTION device show "$iface" 2>/dev/null | head -n1)
ip=$(nmcli -g IP4.ADDRESS device show "$iface" 2>/dev/null | head -n1)
ip=${ip%%/*}
gateway=$(ip route show default 2>/dev/null | awk 'NR==1 {print $3}')

signal=""
if [ "$type" = "wifi" ]; then
    signal=$(nmcli -t -f IN-USE,SIGNAL device wifi list ifname "$iface" 2>/dev/null | awk -F: '$1=="*" {print $2; exit}')
fi

vpn="OFF"
class="online"
if nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | grep -Eq '^(mikrotik):|:wireguard$'; then
    vpn="ON"
    class="vpn"
fi

extra=""
[ -n "$signal" ] && extra="\\nSIGNAL ${signal}%"
printf '{"text":"COMMS ●","tooltip":"LINK   %s\\nTYPE   %s\\nIFACE  %s\\nADDR   %s\\nGW     %s%s\\nWG     %s","class":"%s"}\n' \
    "${conn:-connected}" "${type:-n/a}" "$iface" "${ip:-n/a}" "${gateway:-n/a}" "$extra" "$vpn" "$class"
