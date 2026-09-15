#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
PROFILE="${1:-aor1}"
case "$PROFILE" in
  clean) WP="$ROOT/wallpapers/SwirlDeskFIELD/field-topo-minimal-1920x1200.png" ;;
  aor1) WP="$ROOT/wallpapers/SwirlDeskFIELD/field-topo-aor1-ghost-1920x1200.png" ;;
  multicam) WP="$ROOT/wallpapers/SwirlDeskFIELD/field-topo-multicam-ghost-1920x1200.png" ;;
  *) echo "profile must be clean, aor1, or multicam" >&2; exit 2 ;;
esac
[[ -f "$WP" ]] || { echo "Missing wallpaper: $WP" >&2; exit 1; }
mkdir -p "$ROOT/state"
printf '%s\n' "$PROFILE" > "$ROOT/state/plasma_field_profile"
if [[ -x "$ROOT/plasma/field/scripts/sync-lockscreen.sh" ]]; then
  "$ROOT/plasma/field/scripts/sync-lockscreen.sh" "$PROFILE" >/dev/null 2>&1 || true
fi
if command -v plasma-apply-wallpaperimage >/dev/null 2>&1 && pgrep -x plasmashell >/dev/null 2>&1; then
  if plasma-apply-wallpaperimage --help 2>&1 | grep -q -- '--fill-mode'; then
    plasma-apply-wallpaperimage --fill-mode preserveAspectCrop "$WP"
  else
    plasma-apply-wallpaperimage "$WP"
  fi
  echo "FIELD // PLASMA visual profile: ${PROFILE^^}"
else
  echo "Profile saved as ${PROFILE^^}. Apply it from a running Plasma session."
fi
