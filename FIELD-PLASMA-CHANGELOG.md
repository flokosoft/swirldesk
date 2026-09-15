# SwirlDesk FIELD // Plasma 0.9.3.7

## Direct monochrome Signal + Bitwarden tray delegate

This revision is intentionally narrow. All working interaction behavior from
0.9.3.5/0.9.3.6 remains unchanged.

### Root cause fixed

The 0.9.3.6 doctor showed that the FIELD Signal/Bitwarden SVG files were
present in the local system-tray plasmoid, while the actual
`StatusNotifierItem.qml` override was not. That meant Plasma kept rendering
the applications' coloured StatusNotifier pixmaps.

0.9.3.7 no longer edits that QML file in-place. It ships a complete FIELD
`StatusNotifierItem.qml` based on KDE Plasma 6.3.5 and installs it directly
into the user-local system-tray plasmoid.

### Signal / Bitwarden rendering

- Matches Signal and Bitwarden using stable Plasma 6.3.5 StatusNotifier roles:
  `Id`, `Title`, tooltip text and `IconName`.
- Matching items use FIELD-owned local vectors directly:
  `field-chat.svg` and `field-vault.svg`.
- Only those two overrides use Kirigami mask mode.
- Normal colour: warm off-white `#d9d3c3`.
- Hover/attention colour: Coyote `#a68a5b`.
- Kirigami QIcon active mode is disabled for the two overrides so it cannot
  swap the FIELD vector for a coloured application icon.

### Deployment resilience

- Uses a fresh copy of the system tray plasmoid when the standard Plasma path
  is available.
- If the distro path differs, it can reuse an already installed local tray
  plasmoid and still replace the delegate directly.
- The apply step verifies the actual installed QML before restarting Plasma.

### Doctor

- Verifies the 0.9.3.7 delegate revision marker.
- Verifies direct local Signal/Bitwarden vector sources.
- Verifies mask mode, active-mode guard and FIELD colours.
- Compares the installed tray delegate byte-for-byte with the FIELD template.
