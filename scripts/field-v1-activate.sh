#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
THEME="$ROOT/themes/swirldesk-field"
STATE="$ROOT/state"

printf '%s\n' 'SwirlDesk FIELD 1.0 // activation'

# Refuse to activate an incomplete payload before Hyprland is reloaded.
"$ROOT/scripts/field-theme-check.sh" "$THEME"

mkdir -p "$STATE" "$HOME/.local/bin"
for f in "$ROOT"/scripts/*.sh "$ROOT"/scripts/field-*.py "$ROOT"/bin/swirl-field; do
    [ -f "$f" ] && chmod +x "$f"
done
ln -sfn "$ROOT/bin/swirl-field" "$HOME/.local/bin/swirl-field"

# FIELD is already the intended target for this release activator. Replace the
# theme symlink atomically enough for Debian/GNU coreutils and keep runtime
# state (wallpaper profile, monitor profile, notification state) untouched.
tmp="$STATE/.current_theme.$$"
rm -f "$tmp"
ln -s "$THEME" "$tmp"
mv -Tf "$tmp" "$STATE/current_theme"
printf '%s\n' 'swirldesk-field' > "$STATE/current_theme_name"

# Refresh public config links through the project linker; it preserves existing
# non-symlink configs as timestamped backups.
"$ROOT/link.sh" >/dev/null

# Restore selected FIELD visual profile and start the serialized UI.
profile=$(cat "$STATE/field_wallpaper_profile" 2>/dev/null || printf clean)
case "$profile" in clean|aor1|multicam) ;; *) profile=clean;; esac
"$ROOT/scripts/field-wallpaper-profile.sh" --quiet --apply "$profile" >/dev/null 2>&1 || true
hyprctl reload >/dev/null 2>&1 || true
"$ROOT/scripts/restart-ui.sh" >/dev/null 2>&1 || true

printf '%s\n' 'SwirlDesk FIELD 1.0 // READY'
printf '%s\n' 'SUPER+SPACE  FIELD CONTROL (center)'
printf '%s\n' 'SUPER+I      FIELD STATUS  (upper-right)'
printf '%s\n' 'SUPER+CTRL+P FIELD POWER   (center)'
printf '%s\n' 'CLI          swirl-field doctor'
