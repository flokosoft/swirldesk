#!/usr/bin/env bash
set -u

# SwirlDesk FIELD // local-node status console
# Design rule: edge-anchored, high-information, low-decoration. Values are read
# from the local machine only. No simulated tactical data is shown.

C='\033[38;2;166;138;91m'   # coyote
K='\033[38;2;179;160;109m'  # khaki
O='\033[38;2;132;149;107m'  # safe olive
T='\033[38;2;217;211;195m'  # text
M='\033[38;2;144;138;124m'  # muted
W='\033[38;2;196;154;82m'   # warning
X='\033[38;2;146;83;74m'    # critical
R='\033[0m'

bar() {
    local v=${1:-0} width=${2:-18} filled empty color="$O"
    (( v < 0 )) && v=0
    (( v > 100 )) && v=100
    (( v >= 80 )) && color="$W"
    (( v >= 95 )) && color="$X"
    filled=$((v*width/100)); empty=$((width-filled))
    printf '%b' "$color"
    printf '%*s' "$filled" '' | tr ' ' '#'
    printf '%b' "$M"
    printf '%*s' "$empty" '' | tr ' ' '.'
    printf '%b' "$R"
}

cpu_usage() {
    local _ u n s i iw irq sirq st _x idle1 total1 idle2 total2 dt di
    read -r _ u n s i iw irq sirq st _x < /proc/stat
    idle1=$((i+iw)); total1=$((u+n+s+i+iw+irq+sirq+st))
    sleep 0.10
    read -r _ u n s i iw irq sirq st _x < /proc/stat
    idle2=$((i+iw)); total2=$((u+n+s+i+iw+irq+sirq+st))
    dt=$((total2-total1)); di=$((idle2-idle1))
    if (( dt > 0 )); then printf '%d' $((100*(dt-di)/dt)); else printf '0'; fi
}

max_temp() {
    local max='' v t
    for t in /sys/class/thermal/thermal_zone*/temp; do
        [ -r "$t" ] || continue
        v=$(cat "$t" 2>/dev/null || true)
        [[ "$v" =~ ^[0-9]+$ ]] || continue
        (( v > 120000 )) && continue
        if [ -z "$max" ] || (( v > max )); then max=$v; fi
    done
    if [ -n "$max" ]; then printf '%d°C' $((max/1000)); else printf -- '--'; fi
}

battery_eta() {
    if ! command -v upower >/dev/null 2>&1; then printf -- '--'; return; fi
    local dev eta
    dev=$(upower -e 2>/dev/null | grep -m1 '/battery_' || true)
    [ -n "$dev" ] || { printf -- '--'; return; }
    eta=$(upower -i "$dev" 2>/dev/null | awk -F: '/time to empty|time to full/ {gsub(/^[ \t]+/,"",$2); print $2; exit}')
    [ -n "$eta" ] && printf '%s' "$eta" || printf -- '--'
}

product=$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || echo 'Linux node')

while :; do
    printf '\033[2J\033[H'

    host=$(hostname 2>/dev/null || echo unknown)
    kernel=$(uname -r)
    uptime=$(uptime -p 2>/dev/null | sed 's/^up //' || true)
    cpu=$(cpu_usage)
    temp=$(max_temp)
    load=$(awk '{print $1" "$2" "$3}' /proc/loadavg 2>/dev/null || echo '--')

    mem_total=$(awk '/MemTotal:/ {print $2}' /proc/meminfo)
    mem_avail=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)
    mem_used=$((mem_total-mem_avail)); mem_pct=$((100*mem_used/mem_total))
    mem_used_g=$(awk -v k="$mem_used" 'BEGIN {printf "%.1f", k/1024/1024}')
    mem_total_g=$(awk -v k="$mem_total" 'BEGIN {printf "%.1f", k/1024/1024}')

    iface=$(nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null | awk -F: '$3=="connected" && ($2=="wifi" || $2=="ethernet") {print $1; exit}')
    conn='OFFLINE'; ip4='--'; signal='--'; wg='OFF'; link_type='--'; gateway='--'
    if [ -n "${iface:-}" ]; then
        conn=$(nmcli -g GENERAL.CONNECTION device show "$iface" 2>/dev/null | head -n1)
        ip4=$(nmcli -g IP4.ADDRESS device show "$iface" 2>/dev/null | head -n1); ip4=${ip4%%/*}
        link_type=$(nmcli -g GENERAL.TYPE device show "$iface" 2>/dev/null | head -n1)
        gateway=$(ip route show default 2>/dev/null | awk 'NR==1 {print $3}')
        if [ "$link_type" = 'wifi' ]; then
            signal=$(nmcli -t -f IN-USE,SIGNAL device wifi list ifname "$iface" 2>/dev/null | awk -F: '$1=="*" {print $2; exit}')
            [ -n "$signal" ] || signal='--'
        fi
    fi
    if nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | grep -Eq '^(mikrotik):|:wireguard$'; then wg='ON'; fi

    bat=$(find /sys/class/power_supply -maxdepth 1 -type l -name 'BAT*' 2>/dev/null | head -n1)
    cap='--'; bstat='N/A'; eta='--'
    if [ -n "${bat:-}" ] && [ -r "$bat/capacity" ]; then
        cap=$(cat "$bat/capacity")
        bstat=$(cat "$bat/status" 2>/dev/null || echo Unknown)
        eta=$(battery_eta)
    fi

    visual=$(cat "$HOME/.config/swirldesk/state/field_wallpaper_profile" 2>/dev/null || echo clean)
    root_used=$(df -P / | awk 'NR==2 {gsub(/%/,"",$5); print $5}')
    root_label=$(df -hP / | awk 'NR==2 {print $3" / "$2}')
    local_time=$(date '+%H:%M:%S')
    zulu_time=$(TZ=UTC date '+%H:%M:%SZ')

    printf "${C}FIELD // STATUS${R}    ${M}NODE ${host}    ${K}%s L${R}  ${M}/  %s${R}\n" "$local_time" "$zulu_time"
    printf "${M}────────────────────────────────────────────────────${R}\n"
    printf "${M}PLATFORM  %-22s  PROFILE  %-10s${R}\n" "${product:0:22}" "${visual^^}"
    printf "${M}DATE      %-22s  SOURCE   LOCAL${R}\n" "$(date '+%d %b %Y')"

    printf "\n${C}[01]${R} ${K}SYSTEM${R}\n"
    printf "  CPU      ${T}%3s%%${R}  %-6s  " "$cpu" "$temp"; bar "$cpu" 18; printf "\n"
    printf "  MEMORY   ${T}%3d%%${R}  %4s/%-7s " "$mem_pct" "$mem_used_g" "$mem_total_g"; bar "$mem_pct" 18; printf "\n"
    printf "  LOAD     ${T}%-20s${R} KERNEL  ${T}%s${R}\n" "$load" "$kernel"
    printf "  UPTIME   ${T}%s${R}\n" "${uptime:-n/a}"

    printf "\n${C}[02]${R} ${K}COMMS${R}\n"
    if [ -n "${iface:-}" ]; then
        printf "  LINK     ${O}● ONLINE${R}     TYPE    ${T}%s${R}\n" "${link_type:-n/a}"
        printf "  NAME     ${T}%-20s${R} IFACE   ${T}%s${R}\n" "${conn:0:20}" "$iface"
        printf "  ADDR     ${T}%-20s${R} GW      ${T}%s${R}\n" "$ip4" "$gateway"
    else
        printf "  LINK     ${W}○ OFFLINE${R}\n"
        printf "  NAME     ${M}--${R}\n  ADDR     ${M}--${R}\n"
    fi
    if [ "$signal" != '--' ]; then printf "  SIGNAL   ${T}%3s%%${R}                " "$signal"; bar "$signal" 18; printf "\n"; fi
    if [ "$wg" = 'ON' ]; then printf "  WG       ${O}● ACTIVE${R}\n"; else printf "  WG       ${M}○ OFF${R}\n"; fi

    printf "\n${C}[03]${R} ${K}POWER${R}\n"
    if [ "$cap" != '--' ]; then
        printf "  BATTERY  ${T}%3s%%${R}  %-12s " "$cap" "$bstat"; bar "$cap" 18; printf "\n"
        printf "  EST      ${T}%s${R}\n" "$eta"
    else
        printf "  BATTERY  ${M}not detected${R}\n"
    fi

    printf "\n${C}[04]${R} ${K}STORAGE${R}\n"
    printf "  ROOT     ${T}%-16s${R} %3s%%  " "$root_label" "${root_used:-0}"; bar "${root_used:-0}" 18; printf "\n"

    printf "\n${M}────────────────────────────────────────────────────${R}\n"
    printf "${M}REFRESH 2S  //  SUPER+I CLOSE  //  SOURCE LOCAL${R}\n"
    sleep 1.9
done
