#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
FIELD="$ROOT/plasma/field"
mkdir -p "$HOME/.local/share/color-schemes" "$ROOT/state"
install -m 0644 "$FIELD/colors/SwirlDeskFIELD.colors" "$HOME/.local/share/color-schemes/SwirlDeskFIELD.colors"
[[ -f "$ROOT/state/plasma_field_profile" ]] || printf 'aor1\n' > "$ROOT/state/plasma_field_profile"
chmod +x "$FIELD/scripts/"*.sh

echo 'FIELD // PLASMA v0.8 installed.'
if pgrep -x plasmashell >/dev/null 2>&1; then
  echo 'Applying FIELD Plasma style, Konsole profile and visual foundation.'
  "$FIELD/scripts/apply-field.sh"
  echo
  echo 'Then run: swirl-field plasma panel apply'
  echo 'Interaction parity: swirl-field plasma interaction apply
  Window polish:      swirl-field plasma window apply
  Shell cohesion:     swirl-field plasma shell apply'
else
  echo 'Log into Plasma, then run:'
  echo '  swirl-field plasma apply'
  echo '  swirl-field plasma panel apply'
  echo '  swirl-field plasma interaction apply'
  echo '  swirl-field plasma window apply'
  echo '  swirl-field plasma shell apply'
fi
