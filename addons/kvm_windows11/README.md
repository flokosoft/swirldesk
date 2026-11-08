# SwirlDesk Addon: KVM Windows 11

Standalone-Addon für Debian 13 + Hyprland; Windows 11 per libvirt `qemu:///system`, SDL-FreeRDP und GNOME Keyring.

## Installation

Im Addon-Verzeichnis `./install.sh` als normaler Benutzer ausführen. Das Skript fordert bei Bedarf `sudo` für APT und Gruppenmitgliedschaft an. Anschließend ab- und anmelden, falls die Gruppen neu hinzugefügt wurden.

## Voraussetzung / Umfang

Die Windows-11-VM mit Name `win11` und MAC `52:54:00:f2:67:92` ist ein Beispiel aus der bestehenden Einrichtung. Die VM muss vorhanden sein oder separat aus Backup/Installationsmedium eingerichtet werden. Die libvirt-NAT-Netzwerkdefinition `default` muss vorhanden und aktiv sein. Windows 11 Pro muss RDP erlauben, die Firewall TCP 3389 zulassen und eine Passwort-Anmeldung akzeptieren. Ein Microsoft-Account-PIN ist kein RDP-Passwort.

Die VM-Festplatte, Windows-Installation, Windows-Konto und RDP-Freigabe werden nicht automatisch erstellt oder verändert. SwirlDesk-Hyprland-Regeln (Workspace 10, `bindp`-Shortcuts) sind bereits Teil des Hauptsetups und werden nicht verändert.

## Konfiguration

`~/.config/kvm_windows11/config`: VM, Connection, Netzwerk, MAC, Benutzer, Domain, Workspace und Timeout. Für ein neues System MAC mit `virsh -c qemu:///system domiflist win11` ermitteln. RDP-Domain muss der tatsächlich funktionierenden Anmeldung entsprechen.

Passwort sicher speichern oder erneuern:

```bash
secret-tool store --label='Windows 11 KVM RDP' application win11-kvm credential rdp
```

Die Keyring-DBus-Sitzung muss in Hyprland funktionieren; ggf. GNOME Keyring beim Login initialisieren/entsperren. Das Installationsskript speichert keine Geheimnisse im Addon.

## Start / Bedienung

Anwendungsmenü -> Windows 11 oder `~/.local/bin/windows11`. Bei laufendem FreeRDP wird nur zu Workspace 10 gewechselt. `SUPER+0` = Windows, `SUPER+1` usw. = Linux. Zum Trennen das FreeRDP-Fenster über den eingerichteten Hyprland-Shortcut schließen; die VM bleibt an.

## Deinstallation

`./uninstall.sh`. Keine VM, Festplatte, Schlüssel oder Systempakete werden gelöscht.

## Sicherheit / Einschränkungen

`/args-from:stdin` verhindert das Passwort in der Prozessargumentliste, nicht aber dessen kurzzeitige Existenz im RAM. Das Addon verwendet die zuvor erprobte FreeRDP-Option `/cert:tofu` (Trust on First Use). Ein bereits vorhandenes, unerwartet geändertes Zertifikat sollte nicht blind bestätigt werden. Das Konfigurationsfile wird als Shell-Code eingelesen: nur selbst gepflegte Dateien verwenden.

Die Fenster-Erkennung setzt voraus, dass die FreeRDP-Fensterklasse `sdl-freerdp3` heißt. Bei anderen Versionen ggf. anpassen. Die Installer-Skripte sind nicht auf dem Zielrechner live getestet.
