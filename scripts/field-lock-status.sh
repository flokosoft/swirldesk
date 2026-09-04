#!/usr/bin/env bash
set -u

mode="${1:-status}"

machine_name() {
    local model host
    model=$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)
    host=$(hostname 2>/dev/null || echo linux)
    [ -n "$model" ] || model="LINUX WORKSTATION"
    printf '%s // %s\n' "${model^^}" "${host^^}"
}

profile_header() {
    local profile host
    profile=$(cat "$HOME/.config/swirldesk/state/field_wallpaper_profile" 2>/dev/null || echo clean)
    host=$(hostname 2>/dev/null || echo linux)
    printf 'PROFILE %s // NODE %s\n' "${profile^^}" "${host^^}"
}

user_name() {
    local display user
    user=$(id -un 2>/dev/null || echo user)
    display=$(cat "$HOME/.config/swirldesk/state/display_name" 2>/dev/null || true)
    [ -n "$display" ] || display="$user"
    printf 'AUTH // %s\n' "${display^^}"
}

network_state() {
    local iface conn vpn="WG OFF"
    iface=$(nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null | awk -F: '$3=="connected" && ($2=="wifi" || $2=="ethernet") {print $1; exit}')
    if [ -n "${iface:-}" ]; then
        conn=$(nmcli -g GENERAL.CONNECTION device show "$iface" 2>/dev/null | head -n1)
        [ -n "$conn" ] || conn="$iface"
        conn="NET ${conn^^}"
    else
        conn="NET OFFLINE"
    fi

    if nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | grep -Eq '^(mikrotik):|:wireguard$'; then
        vpn="WG ON"
    fi
    printf '%s // %s' "$conn" "$vpn"
}

power_state() {
    local bat cap status
    bat=$(find /sys/class/power_supply -maxdepth 1 -type l -name 'BAT*' 2>/dev/null | head -n1)
    if [ -n "${bat:-}" ] && [ -r "$bat/capacity" ]; then
        cap=$(cat "$bat/capacity" 2>/dev/null || echo --)
        status=$(cat "$bat/status" 2>/dev/null || echo unknown)
        case "$status" in
            Charging) status="CHG" ;;
            Discharging) status="BAT" ;;
            Full|"Not charging") status="AC" ;;
            *) status="PWR" ;;
        esac
        printf '%s %s%%' "$status" "$cap"
    else
        printf 'PWR AC'
    fi
}

case "$mode" in
    identity) machine_name ;;
    time) printf '%s L  //  %s\n' "$(date '+%H:%M:%S')" "$(TZ=UTC date '+%H:%M:%SZ')" ;;
    profile) profile_header ;;
    user) user_name ;;
    status)
        printf '[01] COMMS  %s    [02] PWR  %s\n' "$(network_state)" "$(power_state)"
        ;;
    *) exit 2 ;;
esac
