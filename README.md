# SwirlDesk

SwirlDesk ist ein persönliches Hyprland-Desktop-Setup für Debian mit Fokus auf:

- Hyprland
- Waybar
- Fuzzel
- Dunst
- Kitty
- Wallpaper-Auswahl
- SwirlDesk Control Center
- Theme-System
- Debian/ThinkPad-freundliche Struktur

VPN erstellen (Beispiel):

```
mkdir -p ~/.config/wireguard
cd ~/.config/wireguard
wg genkey | tee privatekey | wg pubkey > publickey
chmod 600 privatekey

~/.config/wireguard/mikrotik.conf

[Interface] 
PrivateKey = Geheimer-KEY-Geraet
Address = 10.0.80.3/32
DNS = 10.0.60.2

[Peer]
PublicKey = Public-Key Router/ Mikrotik/ Server
Endpoint = Domain/IP-Endpunkt:Port
AllowedIPs = 10.0.0.0/8
PersistentKeepalive = 25

sudo nmcli connection import type wireguard file ~/.config/wireguard/mikrotik.conf
sudo nmcli connection modify mikrotik connection.autoconnect no
```

Aktivieren: Shift+Super+V / nmcli connection up mikrotik


## Installation

```bash
git clone https://github.com/flokosoft/swirldesk.git  ~/.config/swirldesk
cd ~/.config/swirldesk
./install.sh

## LID systemd

```bash
sudo mkdir -p /etc/systemd/logind.conf.d
sudo nano /etc/systemd/logind.conf.d/90-swirldesk-lid.conf

Inhalt:
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
