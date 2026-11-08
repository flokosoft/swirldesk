#!/usr/bin/env bash
set -euo pipefail
rm -f "$HOME/.local/bin/windows11" "$HOME/.local/share/applications/windows11.desktop"
echo 'Starter und Menüeintrag entfernt. Konfiguration, Keyring, VM und installierte Pakete bleiben erhalten.'
echo 'Optionale Konfiguration: ~/.config/kvm_windows11/config'
