#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"
[[ $EUID -ne 0 ]] || { echo 'Bitte als normaler Benutzer starten, nicht mit sudo.' >&2; exit 1; }
[[ -f /etc/debian_version ]] || { echo 'Dieses Addon unterstützt Debian.' >&2; exit 1; }
command -v apt-get >/dev/null || exit 1
printf 'Installiere KVM/FreeRDP/Keyring-Abhängigkeiten (sudo erforderlich) ...\n'
sudo apt-get update
sudo apt-get install -y qemu-system-x86 qemu-utils libvirt-daemon-system libvirt-clients virt-manager dnsmasq-base freerdp3-sdl gnome-keyring libsecret-tools netcat-openbsd libnotify-bin
sudo usermod -aG libvirt,kvm "$USER"
if command -v systemctl >/dev/null; then
  sudo systemctl enable --now libvirtd.service 2>/dev/null || true
fi
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications" "$HOME/.config/kvm_windows11"
install -m 700 windows11.sh "$HOME/.local/bin/windows11"
if [[ ! -f "$HOME/.config/kvm_windows11/config" ]]; then
  install -m 600 config.example "$HOME/.config/kvm_windows11/config"
fi
sed "s|@HOME@|$HOME|g" windows11.desktop.in > "$HOME/.local/share/applications/windows11.desktop"
chmod 644 "$HOME/.local/share/applications/windows11.desktop"
if ! secret-tool lookup application win11-kvm credential rdp >/dev/null 2>&1; then
  echo
  echo 'RDP-Passwort jetzt sicher im GNOME Keyring speichern (Eingabe bleibt unsichtbar):'
  if [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
    secret-tool store --label='Windows 11 KVM RDP' application win11-kvm credential rdp || echo 'Keyring nicht verfügbar; später mit secret-tool store nachholen.'
  else
    echo 'Kein DBus-Sitzungsbus erkannt. Passwort bitte später in der Hyprland-Sitzung speichern.'
  fi
fi
cat <<'MSG'

Installation abgeschlossen.
- Menüeintrag: Windows 11
- Konfiguration: ~/.config/kvm_windows11/config
- Starter: ~/.local/bin/windows11
- Windows-VM und Windows-RDP müssen separat eingerichtet sein.
- Nach neuer libvirt/kvm-Gruppenmitgliedschaft bitte ab- und wieder anmelden.
- SwirlDesk-Workspace-Regel und bindp-Shortcuts werden NICHT verändert.
MSG
