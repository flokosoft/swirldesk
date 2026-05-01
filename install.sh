#!/usr/bin/env bash
set -euo pipefail

SWIRL_DIR="$HOME/.config/swirldesk"
PKG_FILE="$SWIRL_DIR/packages/debian.txt"

echo "======================================"
echo "        SwirlDesk Installer"
echo "======================================"
echo

if ! command -v apt >/dev/null 2>&1; then
    echo "Dieses Installationsscript ist aktuell für Debian/apt gedacht."
    exit 1
fi

if [ ! -d "$SWIRL_DIR" ]; then
    echo "SwirlDesk-Verzeichnis nicht gefunden: $SWIRL_DIR"
    echo "Bitte zuerst das Repo nach ~/.config/swirldesk klonen."
    exit 1
fi

DEBIAN_CODENAME="$(
    . /etc/os-release
    echo "${VERSION_CODENAME:-}"
)"
BACKPORTS_SUITE="${DEBIAN_CODENAME}-backports"

has_backports() {
    [ -n "$DEBIAN_CODENAME" ] || return 1

    grep -Rqs "$BACKPORTS_SUITE" \
        /etc/apt/sources.list \
        /etc/apt/sources.list.d/*.list \
        /etc/apt/sources.list.d/*.sources 2>/dev/null
}

add_backports() {
    local sources_file="/etc/apt/sources.list.d/${BACKPORTS_SUITE}.sources"

    echo "==> Trage $BACKPORTS_SUITE ein..."

    sudo tee "$sources_file" >/dev/null <<EOF
Types: deb
URIs: http://deb.debian.org/debian
Suites: $BACKPORTS_SUITE
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

    echo "==> Backports eingetragen: $sources_file"
}

echo "==> Debian-Codename: ${DEBIAN_CODENAME:-unbekannt}"

if [ -z "$DEBIAN_CODENAME" ]; then
    echo "FEHLER: Debian-Codename konnte nicht ermittelt werden."
    exit 1
fi

if has_backports; then
    echo "==> Backports gefunden: $BACKPORTS_SUITE"
else
    echo "==> Backports wurden nicht gefunden: $BACKPORTS_SUITE"
    echo
    read -r -p "Soll $BACKPORTS_SUITE automatisch eingetragen werden? [Y/n] " reply
    reply="${reply:-Y}"

    case "$reply" in
        Y|y|J|j|"")
            add_backports
            echo "==> Aktualisiere Paketquellen nach Backports-Eintrag..."
            sudo apt update
            ;;
        *)
            echo "WARNUNG: Ohne Backports könnten einige Pakete fehlen oder zu alt sein."
            echo
            read -r -p "Trotzdem fortfahren? [y/N] " continue_reply
            continue_reply="${continue_reply:-N}"
            case "$continue_reply" in
                Y|y|J|j) ;;
                *)
                    echo "Abbruch."
                    exit 1
                    ;;
            esac
            ;;
    esac
fi

echo "==> Erstelle benötigte Ordner..."
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/Bilder/Wallpapers"
mkdir -p "$HOME/Bilder/Screenshots"
mkdir -p "$SWIRL_DIR/state"
mkdir -p "$HOME/.config/hypr/conf"
mkdir -p "$HOME/.config/waybar"
mkdir -p "$HOME/.config/fuzzel"
mkdir -p "$HOME/.config/dunst"
mkdir -p "$HOME/.config/kitty"

echo "==> Aktualisiere Paketquellen..."
sudo apt update

echo "==> Installiere benötigte Pakete..."

if [ -f "$PKG_FILE" ]; then
    while read -r pkg; do
        [ -z "$pkg" ] && continue
        [[ "$pkg" =~ ^# ]] && continue

        echo "----> Paket: $pkg"

        if ! sudo apt install -y -t "$BACKPORTS_SUITE" "$pkg"; then
            echo "WARNUNG: Backports-Installation fehlgeschlagen für: $pkg"
            echo "         Versuche normale Installation..."

            if ! sudo apt install -y "$pkg"; then
                echo "WARNUNG: Paket konnte nicht installiert werden: $pkg"
                echo "         Wir machen weiter."
            fi
        fi
    done < "$PKG_FILE"
else
    echo "WARNUNG: Paketliste nicht gefunden: $PKG_FILE"
fi

echo
echo "==> Setze Script-Rechte..."
find "$SWIRL_DIR/scripts" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
find "$SWIRL_DIR/bin" -type f -exec chmod +x {} \; 2>/dev/null || true

if [ -f "$SWIRL_DIR/link.sh" ]; then
    chmod +x "$SWIRL_DIR/link.sh"
else
    echo "FEHLER: link.sh nicht gefunden."
    exit 1
fi

echo
echo "==> Setze Symlinks..."
"$SWIRL_DIR/link.sh"

echo
echo "==> Prüfe PATH..."

if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    SHELL_NAME="$(basename "${SHELL:-bash}")"

    if [ "$SHELL_NAME" = "zsh" ]; then
        RC_FILE="$HOME/.zshrc"
    else
        RC_FILE="$HOME/.bashrc"
    fi

    if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$RC_FILE" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$RC_FILE"
        echo "PATH wurde in $RC_FILE ergänzt."
    fi
fi

echo
echo "==> Prüfe SwirlDesk-Verlinkung..."

[ -L "$HOME/.config/hypr/hyprland.conf" ] || echo "WARNUNG: ~/.config/hypr/hyprland.conf ist kein Symlink"
[ -L "$HOME/.config/waybar/config" ] || echo "WARNUNG: ~/.config/waybar/config ist kein Symlink"
[ -L "$HOME/.config/fuzzel/fuzzel.ini" ] || echo "WARNUNG: ~/.config/fuzzel/fuzzel.ini ist kein Symlink"
[ -L "$HOME/.config/dunst/dunstrc" ] || echo "WARNUNG: ~/.config/dunst/dunstrc ist kein Symlink"

echo
echo "==> Installation abgeschlossen."
echo
echo "Möglicherweise ist eine neue Shell oder ein Re-Login sinnvoll."
echo "Hyprland neu laden:"
echo "  hyprctl reload"
echo
echo "SwirlDesk öffnen:"
echo "  SUPER + SPACE"
echo
