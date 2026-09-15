#!/usr/bin/env bash
set -euo pipefail
mode="${1:-area}"
SPECTACLE="$(command -v spectacle 2>/dev/null || true)"
if [[ -z "$SPECTACLE" ]]; then
  notify-send 'FIELD // CAPTURE' 'Spectacle fehlt. Installieren: sudo apt install kde-spectacle' 2>/dev/null || true
  echo 'FIELD // CAPTURE: spectacle not found. Install with: sudo apt install kde-spectacle' >&2
  exit 127
fi
case "$mode" in
  area)   exec "$SPECTACLE" -r -b ;;
  window) exec "$SPECTACLE" -a -b ;;
  screen) exec "$SPECTACLE" -f -b ;;
  *) exit 2 ;;
esac
