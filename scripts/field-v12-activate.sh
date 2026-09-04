#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
THEME="$ROOT/themes/swirldesk-field"
STATE="$ROOT/state"

printf '%s\n' 'SwirlDesk FIELD 1.2 // activation'
"$ROOT/scripts/field-theme-check.sh" "$THEME"

mkdir -p "$STATE" "$HOME/.local/bin"
for f in "$ROOT"/scripts/*.sh "$ROOT"/scripts/field-*.py "$ROOT"/bin/swirl-field; do
    [ -f "$f" ] && chmod +x "$f"
done
ln -sfn "$ROOT/bin/swirl-field" "$HOME/.local/bin/swirl-field"

tmp="$STATE/.current_theme.$$"
rm -f "$tmp"
ln -s "$THEME" "$tmp"
mv -Tf "$tmp" "$STATE/current_theme"
printf '%s\n' 'swirldesk-field' > "$STATE/current_theme_name"

"$ROOT/link.sh" >/dev/null
profile=$(cat "$STATE/field_wallpaper_profile" 2>/dev/null || printf clean)
case "$profile" in clean|aor1|multicam) ;; *) profile=clean;; esac
"$ROOT/scripts/field-wallpaper-profile.sh" --quiet --apply "$profile" >/dev/null 2>&1 || true
hyprctl reload >/dev/null 2>&1 || true
"$ROOT/scripts/restart-ui.sh" >/dev/null 2>&1 || true

printf '%s\n' 'SwirlDesk FIELD 1.2 // READY'
printf '%s\n' 'SUPER+SPACE      FIELD CONTROL'
printf '%s\n' 'SUPER+I          FIELD STATUS'
printf '%s\n' 'SUPER+CTRL+P     FIELD POWER'
printf '%s\n' 'SUPER+SHIFT+F1   FIELD KEYMAP'
printf '%s\n' 'Login check:     swirl-field greet check'
printf '%s\n' 'System check:    swirl-field doctor'
