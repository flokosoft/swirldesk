#!/usr/bin/env bash

CPU_MODEL="$(awk -F': ' '/model name/ {print $2; exit}' /proc/cpuinfo)"
[ -z "$CPU_MODEL" ] && CPU_MODEL="unbekannt"

CPU_CORES="$(awk -F': ' '/cpu cores/ {print $2; exit}' /proc/cpuinfo)"
CPU_THREADS="$(nproc)"

[ -z "$CPU_CORES" ] && CPU_CORES="?"
[ -z "$CPU_THREADS" ] && CPU_THREADS="?"

RAM_TOTAL="$(LANG=C free -h | awk '/^Mem:/ {print $2}')"
[ -z "$RAM_TOTAL" ] && RAM_TOTAL="unbekannt"

DISK_ROOT="$(df -h / | awk 'NR==2 {print $3 " / " $2 " belegt (" $5 ")"}')"
[ -z "$DISK_ROOT" ] && DISK_ROOT="unbekannt"

KERNEL="$(uname -r)"
HOST="$(hostname)"
UPTIME="$(uptime -p | sed 's/up //')"

BAT="kein Akku"
BAT_STATUS="unbekannt"
AC_STATUS="unbekannt"

if [ -f /sys/class/power_supply/BAT0/capacity ]; then
    BAT="$(cat /sys/class/power_supply/BAT0/capacity)%"
fi

if [ -f /sys/class/power_supply/BAT0/status ]; then
    BAT_STATUS="$(cat /sys/class/power_supply/BAT0/status)"
fi

case "$BAT_STATUS" in
    Charging) BAT_STATUS="lädt" ;;
    Discharging) BAT_STATUS="entlädt" ;;
    Full) BAT_STATUS="voll" ;;
    Not\ charging) BAT_STATUS="lädt nicht" ;;
esac

if [ -f /sys/class/power_supply/AC/online ]; then
    if [ "$(cat /sys/class/power_supply/AC/online)" = "1" ]; then
        AC_STATUS="Netzteil angeschlossen"
    else
        AC_STATUS="Akku-Betrieb"
    fi
fi

INFO="  SwirlDesk Systeminfo

Rechner:      $HOST
Kernel:       $KERNEL
Laufzeit:     $UPTIME

CPU:          $CPU_MODEL
Kerne:        $CPU_CORES
Threads:      $CPU_THREADS

RAM gesamt:   $RAM_TOTAL
SSD /:        $DISK_ROOT

Akku:         $BAT
Akkustatus:   $BAT_STATUS
Strom:        $AC_STATUS"

choice=$(printf "󰓅  htop öffnen\n  btop öffnen\n\n%s" "$INFO" | fuzzel \
    --dmenu \
    --prompt "Systeminfo: " \
    --width 78 \
    --lines 20 \
    --font "JetBrainsMono Nerd Font:size=10")

case "$choice" in
    *htop*)
        kitty --class htop-floating -e htop
        ;;

    *btop*)
        kitty --class btop-floating -e btop
        ;;
esac
