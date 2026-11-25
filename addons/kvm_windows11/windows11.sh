#!/usr/bin/env bash
set -euo pipefail

CONFIG="$HOME/.config/kvm_windows11/config"
[[ -r "$CONFIG" ]] || { echo "Konfiguration fehlt: $CONFIG" >&2; exit 1; }
# shellcheck source=/dev/null
source "$CONFIG"

PRESENTATION=false
case "${1:-}" in
    --presentation) PRESENTATION=true ;;
    "") ;;
    *) echo "Unbekannter Parameter: $1" >&2; exit 1 ;;
esac

fail() {
    echo "$*" >&2
    if command -v notify-send >/dev/null; then
        notify-send -u critical 'Windows 11' "$*" || true
    fi
    exit 1
}
warn() {
    echo "$*" >&2
    if command -v notify-send >/dev/null; then
        notify-send 'Windows 11 – Präsentation' "$*" || true
    fi
}

RDP_CLIENT=sdl-freerdp3
if [[ "$PRESENTATION" == true ]]; then
    RDP_CLIENT=xfreerdp3
fi
for cmd in virsh nc secret-tool "$RDP_CLIENT" hyprctl jq pgrep; do
    command -v "$cmd" >/dev/null || fail "Programm fehlt: $cmd"
done

# Beide Clients berücksichtigen; keine zweite RDP-Sitzung öffnen.
CLIENTS=$(hyprctl clients -j) || fail 'Hyprland nicht erreichbar.'
if jq -e 'any(.[]; .class == "sdl-freerdp3" or .class == "xfreerdp")' <<< "$CLIENTS" >/dev/null ||
   pgrep -u "$UID" -x sdl-freerdp3 >/dev/null || pgrep -u "$UID" -x xfreerdp3 >/dev/null; then
    if [[ "$PRESENTATION" == false ]] && jq -e 'any(.[]; .class == "sdl-freerdp3")' <<< "$CLIENTS" >/dev/null; then
        hyprctl dispatch workspace "${WORKSPACE:-10}" >/dev/null
        exit 0
    fi
    fail 'Bitte zuerst die bestehende RDP-Verbindung trennen.'
fi

# Präsentationsgeometrie vor dem Start prüfen. Bewusst nur die getestete
# Konstellation: zwei erweiterte, unrotierte Monitore mit Skalierung 1.
if [[ "$PRESENTATION" == true ]]; then
    MONITORS=$(hyprctl monitors -j) || fail 'Monitore konnten nicht ermittelt werden.'
    GEOMETRY=$(jq -er '
        map(select(.disabled != true and ((.mirrorOf // "none") == "none"))) as $m
        | if ($m|length) != 2 or any($m[]; .scale != 1 or .transform != 0)
          then error("Zwei aktive, unrotierte Monitore mit Skalierung 1 erforderlich") else $m end
        | sort_by(.x) as $s
        | if ($s[0].x + $s[0].width != $s[1].x) or ($s[0].y != $s[1].y)
          then error("Monitore müssen nebeneinander und oben bündig angeordnet sein") else $s end
        | [($s[0].x), ($s[0].y), ($s[0].width + $s[1].width), ([$s[].height]|max),
           (($s | map(select(.name | startswith("eDP-"))) | first | .name) // $s[0].name)] | @tsv
    ' <<< "$MONITORS") || fail 'Präsentation benötigt zwei erweiterte Monitore nebeneinander (Skalierung 100 %, oben bündig).'
    IFS=$'\t' read -r X Y WIDTH HEIGHT MAIN_MONITOR <<< "$GEOMETRY"
    # XWayland muss ebenfalls genau zwei Monitore sehen.
    XMONITORS=$(xfreerdp3 /list:monitor) || fail 'XWayland-Monitorerkennung fehlgeschlagen.'
    XCOUNT=$(grep -Ec '^[[:space:]]*\*?[[:space:]]*\[[0-9]+\]' <<< "$XMONITORS" || true)
    [[ "$XCOUNT" == 2 ]] || fail 'xfreerdp3 erkennt nicht genau zwei Monitore.'
fi

# Windows-VM bei Bedarf starten.
if ! LC_ALL=C virsh -c "$CONNECTION" domstate "$VM" | grep -qx running; then
    virsh -c "$CONNECTION" start "$VM"
fi

IP=''
for ((i=0; i<${WAIT_SECONDS:-120}; i+=2)); do
    IP=$(LC_ALL=C virsh -c "$CONNECTION" net-dhcp-leases "$NETWORK" |
        awk -v mac="$MAC" 'tolower($0) ~ tolower(mac) {split($5,a,"/");print a[1]}' | tail -n1)
    if [[ -n "$IP" ]] && nc -z -w 1 "$IP" 3389 2>/dev/null; then break; fi
    IP=''; sleep 2
done
[[ -n "$IP" ]] || fail 'RDP nicht erreichbar. Windows-RDP und VM-Netzwerk prüfen.'
PASSWORD=$(secret-tool lookup application win11-kvm credential rdp) || fail 'Keyring nicht verfügbar.'
[[ -n "$PASSWORD" ]] || fail 'Kein RDP-Passwort gespeichert.'

RDP_PID=''
BAR_PIDS=()
cleanup() {
    unset PASSWORD
    if [[ -n "$RDP_PID" ]] && kill -0 "$RDP_PID" 2>/dev/null; then
        kill "$RDP_PID" 2>/dev/null || true
        wait "$RDP_PID" 2>/dev/null || true
    fi
    # Nur die zuvor umgeschalteten Waybar-Prozesse erneut umschalten.
    local pid
    for pid in "${BAR_PIDS[@]}"; do
        if [[ $(ps -p "$pid" -o comm= 2>/dev/null || true) == waybar ]]; then
            kill -USR1 "$pid" 2>/dev/null || true
        fi
    done
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

emit_args() {
    printf '/v:%s\n' "$IP"
    printf '/u:%s\n' "$RDP_USER"
    printf '/d:%s\n' "$RDP_DOMAIN"
    printf '/p:%s\n' "$PASSWORD"
    printf '/f\n/cert:tofu\n'
    if [[ "$PRESENTATION" == true ]]; then
        printf '/multimon\n'
        printf '%s\n' '-grab-keyboard'
        printf '%s\n' '-grab-mouse'
    fi
}

if [[ "$PRESENTATION" == false ]]; then
    hyprctl dispatch workspace "${WORKSPACE:-10}" >/dev/null
    emit_args | "$RDP_CLIENT" /args-from:stdin
    exit 0
fi

# Präsentation: Fenster auf dem ThinkPad öffnen, ohne eine feste
# Workspace-Regel für xfreerdp zu verwenden.
hyprctl dispatch focusmonitor "$MAIN_MONITOR" >/dev/null
hyprctl dispatch workspace 7 >/dev/null
"$RDP_CLIENT" /args-from:stdin < <(emit_args) &
RDP_PID=$!
unset PASSWORD

# Auf das konkrete Fenster dieses Prozesses warten.
WINDOW=''
for ((i=0; i<150; i++)); do
    if ! kill -0 "$RDP_PID" 2>/dev/null; then break; fi
    WINDOW=$(hyprctl clients -j | jq -r --argjson pid "$RDP_PID" \
        '[.[] | select(.pid == $pid and .class == "xfreerdp" and .mapped == true)] | first | .address // empty')
    [[ -n "$WINDOW" ]] && break
    sleep 0.2
done
[[ -n "$WINDOW" ]] || fail 'Kein xfreerdp-Fenster gefunden. Start bitte im Terminal prüfen.'
SELECTOR="address:$WINDOW"
sleep 0.5

# Hyprland darf das Fenster nicht in den Vollbildmodus eines einzelnen
# Monitors zwingen. Den RDP-Client-Zustand dabei unverändert lassen.
FULLSCREEN=$(hyprctl clients -j | jq -r --arg a "$WINDOW" '.[] | select(.address == $a) | .fullscreen')
if [[ "$FULLSCREEN" != 0 ]]; then
    hyprctl dispatch focuswindow "$SELECTOR" >/dev/null
    hyprctl dispatch fullscreenstate '0 -1' >/dev/null
fi
hyprctl dispatch movetoworkspace "7,$SELECTOR" >/dev/null
hyprctl dispatch setfloating "$SELECTOR" >/dev/null
# Dekorationen gelten nur für dieses Fenster; keine globale Konfig ändern.
for prop in 'border_size 0' 'rounding 0' 'no_shadow 1' 'decorate 0'; do
    # shellcheck disable=SC2086
    hyprctl setprop "$SELECTOR" $prop >/dev/null || warn "Fenstereigenschaft nicht gesetzt: $prop"
done

# Bereits manuell erfolgreich getestete Dispatchers, nun dynamisch.
hyprctl dispatch resizewindowpixel "exact $WIDTH $HEIGHT,$SELECTOR" >/dev/null
hyprctl dispatch movewindowpixel "exact $X $Y,$SELECTOR" >/dev/null
sleep 0.5
if ! hyprctl clients -j | jq -e --arg a "$WINDOW" --argjson w "$WIDTH" --argjson h "$HEIGHT" \
    --argjson x "$X" --argjson y "$Y" 'any(.[]; .address == $a and .size == [$w,$h] and .at == [$x,$y])' >/dev/null; then
    warn 'Fenstergeometrie weicht ab. Bitte Hyprland-Fensterposition prüfen; Waybar bleibt sichtbar.'
else
    # SIGUSR1 ist standardmäßig ein Toggle. Voraussetzung: Waybar ist
    # beim Start sichtbar und wurde nicht mit anderen Signalaktionen konfiguriert.
    while IFS= read -r pid; do
        [[ -n "$pid" ]] || continue
        if kill -USR1 "$pid" 2>/dev/null; then BAR_PIDS+=("$pid"); fi
    done < <(pgrep -u "$UID" -x waybar || true)
    hyprctl dispatch focuswindow "$SELECTOR" >/dev/null
fi

STATUS=0
wait "$RDP_PID" || STATUS=$?
RDP_PID=''
exit "$STATUS"
