#!/usr/bin/env bash

BAT="/sys/class/power_supply/BAT0"
AC="/sys/class/power_supply/AC"

capacity=$(cat "$BAT/capacity" 2>/dev/null)
status=$(cat "$BAT/status" 2>/dev/null)
online=$(cat "$AC/online" 2>/dev/null)

if [ -z "$capacity" ]; then
    echo '{"text":"","tooltip":"Kein Akku gefunden","class":"missing"}'
    exit 0
fi

icon="󰁹"
class="battery"

if [ "$online" = "1" ]; then
    if [ "$status" = "Charging" ]; then
        icon="󰂄"
        text="$icon Nutzung ${capacity}%"
        class="charging"
    else
        icon="󰚥"
        text="$icon Kabel ${capacity}%"
        class="plugged"
    fi
else
    if [ "$capacity" -le 15 ]; then
        icon="󰂎"
        class="critical"
    elif [ "$capacity" -le 30 ]; then
        icon="󰁺"
        class="warning"
    elif [ "$capacity" -le 50 ]; then
        icon="󰁼"
    elif [ "$capacity" -le 75 ]; then
        icon="󰁾"
    else
        icon="󰁹"
    fi

    text="$icon ${capacity}%"
fi

tooltip="Akku: ${capacity}%\nStatus: ${status}\nNetzteil: "

if [ "$online" = "1" ]; then
    tooltip="${tooltip}angeschlossen"
else
    tooltip="${tooltip}nicht angeschlossen"
fi

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$tooltip" "$class"
