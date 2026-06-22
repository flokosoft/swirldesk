#!/usr/bin/env bash
set -euo pipefail

WORKSPACE=""
FILE=""
SILENT="silent"
MPV_ARGS=()

show_help() {
    cat <<EOF
SwirlDesk mpv workspace launcher

Nutzung:
  mpv-workspace.sh -w <workspace> -f <datei> [--fs]
  mpv-workspace.sh <datei>

Optionen:
  -w <nr>       Ziel-Workspace, z.B. 3
  -f <datei>    Datei
  -n            Ohne 'silent'
  --fs          mpv im Fullscreen starten
  -h            Hilfe
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        -w)
            WORKSPACE="${2:-}"
            shift 2
            ;;
        -f)
            FILE="${2:-}"
            shift 2
            ;;
        -n)
            SILENT=""
            shift
            ;;
        --fs)
            MPV_ARGS+=("--fullscreen")
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            notify-send "SwirlDesk mpv" "Unbekannte Option: $1"
            exit 1
            ;;
        *)
            if [ -z "$FILE" ]; then
                FILE="$1"
            else
                MPV_ARGS+=("$1")
            fi
            shift
            ;;
    esac
done

if [ -z "$WORKSPACE" ]; then
    WORKSPACE="$(printf "1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n" | fuzzel --dmenu --prompt "Workspace: ")"
fi

[ -z "$WORKSPACE" ] && exit 0

if [ -z "$FILE" ]; then
    if command -v yad >/dev/null 2>&1; then
        FILE="$(yad --file --title="Video auswählen" --file-filter="Video files | *.mp4 *.mkv *.webm *.avi *.mov *.m4v" --file-filter="Alle Dateien | *" 2>/dev/null || true)"
    else
        FILE="$(find "$HOME" -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.m4v" \) 2>/dev/null | sort | fuzzel --dmenu --prompt "Video: ")"
    fi
fi

[ -z "$FILE" ] && exit 0

if command -v realpath >/dev/null 2>&1; then
    FILE="$(realpath "$FILE" 2>/dev/null || printf "%s" "$FILE")"
fi

if [ ! -f "$FILE" ]; then
    notify-send "SwirlDesk mpv" "Datei nicht gefunden: $FILE"
    exit 1
fi

RULE="[workspace $WORKSPACE"
if [ -n "$SILENT" ]; then
    RULE="$RULE $SILENT"
fi
RULE="$RULE]"

cmd=(mpv "${MPV_ARGS[@]}" "$FILE")
quoted_cmd="$(printf '%q ' "${cmd[@]}")"

hyprctl dispatch exec "$RULE $quoted_cmd"
