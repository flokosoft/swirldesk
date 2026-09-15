#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
SRC="${1:-$(cat "$ROOT/state/plasma_field_shell_backup" 2>/dev/null || true)}"
[[ -n "$SRC" && -d "$SRC" ]] || { echo 'No FIELD shell backup found.' >&2; exit 1; }
for f in kscreenlockerrc plasmarc krunnerrc; do
  if [[ -f "$SRC/$f" ]]; then cp -a "$SRC/$f" "$HOME/.config/$f"; fi
done
echo "FIELD // Plasma shell config restored from: $SRC"
echo 'Log out/in once if Plasma does not refresh every element immediately.'
