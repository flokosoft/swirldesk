#!/usr/bin/env bash
set -euo pipefail

ROOT="$HOME/.config/swirldesk"
WALLDIR="$ROOT/wallpapers/SwirlDeskFIELD"
STATE="$ROOT/state"
PROFILE_FILE="$STATE/field_wallpaper_profile"
CURRENT_FILE="$STATE/current_wallpaper"
QUIET=0
PROFILE=""

usage() {
    cat <<'TXT'
SwirlDesk FIELD visual profile

Usage:
  field-wallpaper-profile.sh                 # interactive selector
  field-wallpaper-profile.sh clean           # apply profile
  field-wallpaper-profile.sh aor1            # apply profile
  field-wallpaper-profile.sh multicam        # apply profile
  field-wallpaper-profile.sh --apply NAME    # same, automation-friendly
  field-wallpaper-profile.sh --current       # print current profile
  field-wallpaper-profile.sh --quiet NAME    # suppress notification
TXT
}

while [ $# -gt 0 ]; do
    case "$1" in
        --apply)
            [ $# -ge 2 ] || { echo "--apply requires a profile" >&2; exit 2; }
            PROFILE="$2"; shift 2 ;;
        --quiet)
            QUIET=1; shift ;;
        --current)
            if [ -s "$PROFILE_FILE" ]; then cat "$PROFILE_FILE"; else echo clean; fi
            exit 0 ;;
        -h|--help)
            usage; exit 0 ;;
        clean|aor1|multicam)
            PROFILE="$1"; shift ;;
        *)
            echo "Unknown FIELD profile: $1" >&2
            usage >&2
            exit 2 ;;
    esac
done

mkdir -p "$STATE"

if [ -z "$PROFILE" ]; then
    command -v fuzzel >/dev/null 2>&1 || { echo "fuzzel not found" >&2; exit 1; }
    current="$(cat "$PROFILE_FILE" 2>/dev/null || echo clean)"
    choice=$(printf '%s\n' \
        'CLEAN     // TOPO MINIMAL' \
        'AOR1      // DESERT DIGITAL GHOST' \
        'MULTICAM  // ORGANIC GHOST' | \
        fuzzel --dmenu --prompt "VISUAL [$current] // " --width 45 --lines 3 --font 'JetBrainsMono Nerd Font:size=11')
    case "${choice:-}" in
        CLEAN*) PROFILE=clean ;;
        AOR1*) PROFILE=aor1 ;;
        MULTICAM*) PROFILE=multicam ;;
        *) exit 0 ;;
    esac
fi

# Prefer the native 2560x1600 FIELD assets on high-resolution 16:10 panels.
# Fallback is deliberately 1920x1200 so the profile works without jq/hyprctl.
suffix='1920x1200'
if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    width=$(hyprctl monitors -j 2>/dev/null | jq -r '([.[] | select(.focused == true)][0].width // .[0].width // 0)' 2>/dev/null || echo 0)
    if [[ "$width" =~ ^[0-9]+$ ]] && [ "$width" -ge 2400 ]; then
        suffix='2560x1600'
    fi
fi

case "$PROFILE" in
    clean)    file="$WALLDIR/field-topo-minimal-$suffix.png"; label='TOPO MINIMAL' ;;
    aor1)     file="$WALLDIR/field-topo-aor1-ghost-$suffix.png"; label='AOR1 GHOST' ;;
    multicam) file="$WALLDIR/field-topo-multicam-ghost-$suffix.png"; label='MULTICAM GHOST' ;;
    *) echo "Invalid profile: $PROFILE" >&2; exit 2 ;;
esac

if [ ! -f "$file" ]; then
    # Resolution fallback if only the base 1920x1200 set is installed.
    case "$PROFILE" in
        clean)    file="$WALLDIR/field-topo-minimal-1920x1200.png" ;;
        aor1)     file="$WALLDIR/field-topo-aor1-ghost-1920x1200.png" ;;
        multicam) file="$WALLDIR/field-topo-multicam-ghost-1920x1200.png" ;;
    esac
fi
[ -f "$file" ] || { echo "FIELD wallpaper missing: $file" >&2; exit 1; }
command -v swaybg >/dev/null 2>&1 || { echo "swaybg not found" >&2; exit 1; }

pkill -x swaybg 2>/dev/null || true
swaybg -i "$file" -m fill >/dev/null 2>&1 &
printf '%s\n' "$file" > "$CURRENT_FILE"
printf '%s\n' "$PROFILE" > "$PROFILE_FILE"

# Keep Hyprlock visually aligned with the selected FIELD profile. The target is
# a regular file shipped with the theme (not a symlink), avoiding another
# runtime source/glob dependency.
lock_bg="$ROOT/themes/swirldesk-field/hyprlock/field-background.png"
if [ -d "$(dirname "$lock_bg")" ]; then
    cp -f "$file" "$lock_bg" 2>/dev/null || true
fi

if [ "$QUIET" -eq 0 ] && command -v notify-send >/dev/null 2>&1; then
    notify-send 'FIELD // VISUAL' "$label active"
fi
