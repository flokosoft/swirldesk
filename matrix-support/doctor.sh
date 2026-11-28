#!/usr/bin/env bash
set -u
ROOT="$HOME/.config/swirldesk"
T="$ROOT/themes/swirldesk-matrix"
fail=0
for p in theme.conf hypr/colors.conf hypr/appearance.conf hypr/cursor.conf waybar/config waybar/style.css fuzzel/fuzzel.ini dunst/dunstrc kitty/kitty.conf gtk/settings.ini gtk/gtk-3.css gtk/gtk-4.css hyprlock/hyprlock.conf starship/starship.toml wallpapers/matrix-code.png; do
    if [ -s "$T/$p" ]; then printf 'OK       %s\n' "$p"; else printf 'MISSING  %s\n' "$p"; fail=1; fi
done
if command -v python3 >/dev/null; then
    python3 -m json.tool "$T/waybar/config" >/dev/null && echo 'OK       Waybar JSON' || fail=1
fi
if command -v fc-list >/dev/null; then
    if fc-list : family | grep -i 'JetBrainsMono Nerd Font' >/dev/null; then echo 'OK       JetBrainsMono Nerd Font'; else echo 'INFO     JetBrainsMono Nerd Font not detected; install locally if needed'; fi
fi
if [ ! -L "$ROOT/state/current_theme" ] || [ ! -d "$ROOT/state/current_theme" ]; then
    echo 'MISMATCH state/current_theme is not a valid symlink; do not activate themes until repaired'
    fail=1
fi
active="$(cat "$ROOT/state/current_theme_name" 2>/dev/null || true)"
printf 'INFO     active theme: %s\n' "${active:-unknown}"
if [ "$active" = swirldesk-matrix ]; then
    for p in waybar/config waybar/style.css fuzzel/fuzzel.ini dunst/dunstrc kitty/kitty.conf hypr/hyprlock.conf; do
        expected="$T/$p"; [ "$p" != hypr/hyprlock.conf ] || expected="$T/hyprlock/hyprlock.conf"
        if [ "$(readlink -f "$HOME/.config/$p" 2>/dev/null)" = "$(readlink -f "$expected")" ]; then printf 'OK       active %s\n' "$p"; else printf 'MISMATCH active %s\n' "$p"; fail=1; fi
    done
    if command -v hyprctl >/dev/null && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        errors="$(hyprctl configerrors 2>&1)"; printf 'INFO     Hyprland configerrors: %s\n' "${errors:-none}";
    fi
fi
echo '--- MATRIX // OPERATOR 0.2 ---'
for p in control/open.sh control/fallback.sh control/matrix_operator.py control/operator.css control/telemetry.py; do
    if [ -s "$T/$p" ]; then printf 'OK       %s\n' "$p"; else printf 'MISSING  %s\n' "$p"; fail=1; fi
done
if python3 -c 'import gi; gi.require_version("Gtk", "3.0"); from gi.repository import Gtk' 2>/dev/null; then
    echo 'OK       GTK3 / PyGObject'
else
    echo 'INFO     GTK3 / PyGObject unavailable; Fuzzel fallback (Debian: python3-gi gir1.2-gtk-3.0)'
fi
if cmp -s "$ROOT/scripts/control-center.sh" "$ROOT/matrix-support/control-center.sh.matrix"; then
    echo 'OK       Super+Space MATRIX dispatcher'
else
    echo 'INFO     optional operator dispatcher not enabled; Waybar click still works'
fi
if python3 "$T/control/telemetry.py" >/dev/null; then echo 'OK       local telemetry snapshot'; else echo 'MISMATCH local telemetry snapshot'; fail=1; fi
echo '--- MATRIX // VISUAL 0.3 ---'
for p in wallpapers/matrix-clean.png wallpapers/matrix-code.png wallpapers/matrix-construct.png visual/profile.sh; do
    if [ -s "$T/$p" ]; then printf 'OK       %s\n' "$p"; else printf 'MISSING  %s\n' "$p"; fail=1; fi
done
if cmp -s "$ROOT/scripts/theme-switcher.sh" "$ROOT/matrix-support/theme-switcher.sh.profiles" || cmp -s "$ROOT/scripts/theme-switcher.sh" "$ROOT/matrix-support/theme-switcher.sh.icons"; then
    echo 'OK       automatic MATRIX profile restore'
else
    echo 'INFO     automatic profile restore not enabled; manual selector works'
fi
for cmd in swaybg flock fuzzel; do
    if command -v "$cmd" >/dev/null; then echo "OK       $cmd"; else echo "MISSING  $cmd"; fail=1; fi
done
if [ -x "$T/visual/profile.sh" ]; then
    printf 'INFO     saved visual profile: %s\n' "$("$T/visual/profile.sh" --current)"
    printf 'INFO     wallpaper cache status: %s\n' "$("$T/visual/profile.sh" --status)"
else
    echo 'MISMATCH visual/profile.sh not executable'; fail=1
fi
echo '--- MATRIX // ICON SYSTEM 0.4 ---'
if python3 "$ROOT/matrix-support/check-icons.py"; then echo 'OK       icon assets and config'; else echo 'MISMATCH icon assets or config'; fail=1; fi
if [[ $(readlink -f "$HOME/.local/share/icons/SwirlDesk-MATRIX" 2>/dev/null) == "$T/icons/SwirlDesk-MATRIX" ]] && [[ -L "$HOME/.local/share/icons/SwirlDesk-MATRIX" ]]; then
    echo 'OK       MATRIX icon theme link'
else
    echo 'MISMATCH MATRIX icon theme link; run enable-icons.sh'; fail=1
fi
if cmp -s "$ROOT/scripts/theme-switcher.sh" "$ROOT/matrix-support/theme-switcher.sh.icons"; then
    echo 'OK       MATRIX icon switcher integration'
else
    echo 'MISMATCH MATRIX icon switcher integration'; fail=1
fi
if [[ "$active" == swirldesk-matrix ]]; then
    for v in 3 4; do
        if [[ $(readlink -f "$HOME/.config/gtk-$v.0/settings.ini" 2>/dev/null) == "$T/gtk/settings.ini" ]]; then echo "OK       GTK$v MATRIX settings"; else echo "MISMATCH GTK$v MATRIX settings"; fail=1; fi
    done
    if command -v gsettings >/dev/null; then
        val=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || true)
        printf 'INFO     GSettings icon theme: %s\n' "${val:-unavailable}"
        if [[ -n "$val" && "$val" != "'SwirlDesk-MATRIX'" ]]; then echo 'INFO     GSettings differs; reselect MATRIX if GTK icons are incorrect'; fi
    fi
fi
if command -v waybar >/dev/null; then
    version=$(waybar --version 2>/dev/null || true); printf 'INFO     %s\n' "$version"
    if [[ "$version" =~ 0\.([0-9]+) ]] && (( 10#${BASH_REMATCH[1]} < 15 )); then
        echo 'INFO     direct tray mapping not verified for this version; Debian 0.12 ignores it'
    else
        echo 'INFO     direct tray icon map is best-effort; app pixmap changes may override it'
    fi
fi
if [[ "$active" == swirldesk-matrix ]]; then
    python3 "$ROOT/matrix-support/tray-identities.py" || echo 'INFO     tray diagnostic unavailable'
fi
echo '--- MATRIX // SESSION 0.5 ---'
for p in session/open.sh session/action.sh session/fallback.sh session/power.py session/fetch.sh session/info.sh session/logo.txt session/fastfetch.jsonc; do
    if [[ -s "$T/$p" ]]; then echo "OK       $p"; else echo "MISSING  $p"; fail=1; fi
done
for rel in scripts/power-menu.sh bin/swirlfetch; do
    if cmp -s "$ROOT/$rel" "$ROOT/matrix-support/${rel##*/}.session"; then echo "OK       MATRIX dispatcher $rel"; else echo "INFO     optional dispatcher $rel not enabled"; fi
done
for cmd in hyprlock hypridle fastfetch kitty; do
    if command -v "$cmd" >/dev/null; then echo "OK       $cmd"; else echo "INFO     $cmd unavailable"; fi
done
if [[ "$active" == swirldesk-matrix ]] && [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
    pgrep -u "$(id -u)" -x hypridle >/dev/null && echo 'OK       hypridle running' || echo 'INFO     hypridle not running; MATRIX suspend refused'
fi
echo 'INFO     lockscreen / session commands require local live test; doctor never invokes them'
exit "$fail"
