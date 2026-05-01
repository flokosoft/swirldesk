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
        if ! sudo apt install -y "$pkg"; then
            echo "WARNUNG: Paket konnte nicht installiert werden: $pkg"
            echo "         Wir machen weiter."
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
