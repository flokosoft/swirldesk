#!/usr/bin/env bash
set -u

bat=$(find /sys/class/power_supply -maxdepth 1 -type l -name 'BAT*' 2>/dev/null | head -n1)
if [ -z "${bat:-}" ] || [ ! -r "$bat/capacity" ]; then
    printf '{"text":"PWR AC","tooltip":"POWER  AC\\nBAT    not detected","class":"plugged"}\n'
    exit 0
fi

cap=$(cat "$bat/capacity")
status=$(cat "$bat/status" 2>/dev/null || echo Unknown)
class="normal"
case "$status" in
  Charging) class="charging" ;;
  Full|"Not charging") class="plugged" ;;
esac
if [ "$status" = "Discharging" ]; then
    (( cap <= 15 )) && class="critical"
    (( cap > 15 && cap <= 30 )) && class="warning"
fi

eta='n/a'
if command -v upower >/dev/null 2>&1; then
    dev=$(upower -e 2>/dev/null | grep -m1 '/battery_' || true)
    if [ -n "$dev" ]; then
        eta=$(upower -i "$dev" 2>/dev/null | awk -F: '/time to empty|time to full/ {gsub(/^[ \t]+/,"",$2); print $2; exit}')
        [ -n "$eta" ] || eta='n/a'
    fi
fi

printf '{"text":"PWR %02d","tooltip":"BAT    %d%%\\nSTATE  %s\\nEST    %s","class":"%s"}\n' \
    "$cap" "$cap" "$status" "$eta" "$class"
