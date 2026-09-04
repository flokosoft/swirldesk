#!/usr/bin/env bash
set -u

read -r _ u n s i iw irq sirq st _ < /proc/stat
idle1=$((i + iw)); total1=$((u + n + s + i + iw + irq + sirq + st))
sleep 0.12
read -r _ u n s i iw irq sirq st _ < /proc/stat
idle2=$((i + iw)); total2=$((u + n + s + i + iw + irq + sirq + st))
dt=$((total2-total1)); di=$((idle2-idle1))
if (( dt > 0 )); then cpu=$(( (100*(dt-di))/dt )); else cpu=0; fi

mem_total=$(awk '/MemTotal:/ {print $2}' /proc/meminfo)
mem_avail=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)
mem_used=$((mem_total-mem_avail))
mem_pct=$((100*mem_used/mem_total))
mem_used_g=$(awk -v k="$mem_used" 'BEGIN {printf "%.1f", k/1024/1024}')
mem_total_g=$(awk -v k="$mem_total" 'BEGIN {printf "%.1f", k/1024/1024}')

max_temp=""
for t in /sys/class/thermal/thermal_zone*/temp; do
    [ -r "$t" ] || continue
    v=$(cat "$t" 2>/dev/null || true)
    [[ "$v" =~ ^[0-9]+$ ]] || continue
    (( v > 120000 )) && continue
    if [ -z "$max_temp" ] || (( v > max_temp )); then max_temp=$v; fi
done
if [ -n "$max_temp" ]; then temp="$((max_temp/1000))°C"; else temp="n/a"; fi

uptime_s=$(cut -d. -f1 /proc/uptime 2>/dev/null || echo 0)
up_h=$((uptime_s/3600)); up_m=$(((uptime_s%3600)/60))
load=$(awk '{printf "%s %s %s", $1,$2,$3}' /proc/loadavg 2>/dev/null || echo 'n/a')

class="normal"
(( cpu >= 85 )) && class="warning"
(( cpu >= 95 )) && class="critical"

printf '{"text":"SYS %02d","tooltip":"CPU    %d%%\\nMEM    %s / %s GiB (%d%%)\\nTHERM  %s\\nLOAD   %s\\nUP     %dh %02dm","class":"%s"}\n' \
    "$cpu" "$cpu" "$mem_used_g" "$mem_total_g" "$mem_pct" "$temp" "$load" "$up_h" "$up_m" "$class"
