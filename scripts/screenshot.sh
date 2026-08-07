#!/usr/bin/env bash

set -u

MODE="${1:-area}"
DELAY="${2:-0}"

SCREENSHOT_DIR="$HOME/Bilder/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

FILE="$SCREENSHOT_DIR/screenshot-$(date +%Y%m%d-%H%M%S).png"

# Optionale Verzögerung
if [[ "$DELAY" != "0" ]]; then
    sleep "$DELAY"
fi

case "$MODE" in

    area)
        # Bereich mit der Maus auswählen
        GEOMETRY="$(slurp)" || exit 0
        grim -g "$GEOMETRY" "$FILE"
        ;;

    window)
        # Das JETZT aktive Fenster bestimmen.
        # Wichtig: geschieht erst NACH der Verzögerung.
        GEOMETRY="$(
            hyprctl -j activewindow |
            jq -er '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
        )"

        if [[ -z "$GEOMETRY" ]]; then
            command -v notify-send >/dev/null &&
                notify-send "SwirlDesk Screenshot" "Kein aktives Fenster gefunden."
            exit 1
        fi

        grim -g "$GEOMETRY" "$FILE"
        ;;

    screen)
        # Gesamter Desktop
        grim "$FILE"
        ;;

    *)
        echo "Unbekannter Screenshot-Modus: $MODE"
        echo "Verwendung: $0 {area|window|screen} [delay]"
        exit 1
        ;;
esac

# Benachrichtigung, falls notify-send vorhanden ist
if command -v notify-send >/dev/null; then
    notify-send \
        "SwirlDesk Screenshot" \
        "Screenshot gespeichert:
$FILE"
fi
