#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
PROFILE="${1:-$(cat "$ROOT/state/plasma_field_profile" 2>/dev/null || echo aor1)}"
case "$PROFILE" in
  clean) WP="$ROOT/wallpapers/SwirlDeskFIELD/field-topo-minimal-1920x1200.png" ;;
  aor1) WP="$ROOT/wallpapers/SwirlDeskFIELD/field-topo-aor1-ghost-1920x1200.png" ;;
  multicam) WP="$ROOT/wallpapers/SwirlDeskFIELD/field-topo-multicam-ghost-1920x1200.png" ;;
  *) echo "profile must be clean, aor1, or multicam" >&2; exit 2 ;;
esac
[[ -f "$WP" ]] || { echo "Missing wallpaper: $WP" >&2; exit 1; }
command -v kwriteconfig6 >/dev/null 2>&1 || exit 0
URL="file://$WP"
kwriteconfig6 --file kscreenlockerrc --group Greeter --key WallpaperPlugin org.kde.image
kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "$URL"
kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key PreviewImage "$URL"
printf '%s\n' "$WP" > "$ROOT/state/plasma_field_lockscreen"
echo "FIELD // LOCKSCREEN synced to ${PROFILE^^}"
