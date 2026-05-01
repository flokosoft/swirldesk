#!/usr/bin/env bash

CONF="$HOME/.config/hypr/conf/keybinds.conf"

if ! command -v fuzzel >/dev/null 2>&1; then
    notify-send "Keybinds" "fuzzel ist nicht installiert"
    exit 1
fi

if [ ! -f "$CONF" ]; then
    notify-send "Keybinds" "Datei nicht gefunden: $CONF"
    exit 1
fi

describe_action() {
    local dispatcher="$1"
    local target="$2"

    case "$dispatcher" in
        exec)
            case "$target" in
                *kitty*) echo "Terminal öffnen" ;;
                *thunar*) echo "Dateimanager öffnen" ;;
                *firefox*) echo "Browser öffnen" ;;
                *launcher.sh*) echo "App-Launcher öffnen" ;;
                *quick-menu.sh*) echo "Quick-Menü öffnen" ;;
                *power-menu.sh*) echo "Power-Menü öffnen" ;;
                *wallpaper.sh*) echo "Wallpaper auswählen" ;;
                *wallpaper-random.sh*) echo "Zufälliges Wallpaper setzen" ;;
                *screenshot.sh*) echo "Screenshot-Menü öffnen" ;;
                *clipboard.sh*) echo "Clipboard-Verlauf öffnen" ;;
                *waybar-theme.sh*) echo "Waybar-Theme wechseln" ;;
                *hyprlock*) echo "Bildschirm sperren" ;;
                *) echo "Befehl ausführen: $target" ;;
            esac
            ;;
        killactive) echo "Aktives Fenster schließen" ;;
        fullscreen) echo "Vollbild umschalten" ;;
        exit) echo "Hyprland beenden" ;;
        togglefloating) echo "Floating-Modus umschalten" ;;
        pseudo) echo "Pseudo-Tiling umschalten" ;;
        movefocus)
            case "$target" in
                l) echo "Fokus nach links" ;;
                r) echo "Fokus nach rechts" ;;
                u) echo "Fokus nach oben" ;;
                d) echo "Fokus nach unten" ;;
                *) echo "Fokus bewegen: $target" ;;
            esac
            ;;
        movewindow)
            case "$target" in
                l) echo "Fenster nach links bewegen" ;;
                r) echo "Fenster nach rechts bewegen" ;;
                u) echo "Fenster nach oben bewegen" ;;
                d) echo "Fenster nach unten bewegen" ;;
                *) echo "Fenster bewegen" ;;
            esac
            ;;
        resizewindow) echo "Fenstergröße mit Maus ändern" ;;
        workspace) echo "Zu Workspace $target wechseln" ;;
        movetoworkspace) echo "Fenster zu Workspace $target verschieben" ;;
        *) echo "$dispatcher $target" ;;
    esac
}

format_mods() {
    local mods="$1"

    mods="${mods//\$mainMod/SUPER}"
    mods="${mods//CTRL/STRG}"
    mods="${mods//SHIFT/SHIFT}"
    mods="${mods//ALT/ALT}"

    mods="$(echo "$mods" | xargs)"

    if [ -z "$mods" ]; then
        echo ""
    else
        echo "$mods"
    fi
}

format_key() {
    local mods="$1"
    local key="$2"

    mods="$(format_mods "$mods")"
    key="$(echo "$key" | xargs)"

    case "$key" in
        RETURN) key="ENTER" ;;
        SPACE) key="LEERTASTE" ;;
        left) key="←" ;;
        right) key="→" ;;
        up) key="↑" ;;
        down) key="↓" ;;
        mouse:272) key="Linke Maustaste" ;;
        mouse:273) key="Rechte Maustaste" ;;
    esac

    if [ -z "$mods" ]; then
        echo "$key"
    else
        echo "$mods + $key"
    fi
}

output=""

while IFS= read -r line; do
    line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

    [ -z "$line" ] && continue
    [[ "$line" =~ ^# ]] && continue
    [[ "$line" =~ ^\$ ]] && continue

    if [[ "$line" =~ ^bindm[[:space:]]*= ]]; then
        raw="${line#*=}"
        IFS=',' read -r mods key dispatcher rest <<< "$raw"

        shortcut="$(format_key "$mods" "$key")"
        description="$(describe_action "$(echo "$dispatcher" | xargs)" "$(echo "$rest" | xargs)")"

	output+=$(printf "%-32s  %s" "$shortcut" "$description")
	output+=$'\n'
        continue
    fi

    if [[ "$line" =~ ^bind[[:space:]]*= ]]; then
        raw="${line#*=}"
        IFS=',' read -r mods key dispatcher rest <<< "$raw"

        shortcut="$(format_key "$mods" "$key")"
        dispatcher="$(echo "$dispatcher" | xargs)"
        rest="$(echo "$rest" | xargs)"

        description="$(describe_action "$dispatcher" "$rest")"

	output+=$(printf "%-32s  %s" "$shortcut" "$description")
	output+=$'\n'
        continue
    fi
done < "$CONF"

# selection="$(printf "%s" "$output" | fuzzel --dmenu --prompt "Tastenkürzel: " --width 82 --lines 22)"
selection="$(printf "%s" "$output" | fuzzel --dmenu --prompt "Tastenkürzel: " --width 96 --lines 28 --font 'JetBrainsMono Nerd Font:size=8')"

if [ -n "$selection" ]; then
    echo "$selection" | wl-copy
    notify-send "Tastenkürzel kopiert" "$selection"
fi
