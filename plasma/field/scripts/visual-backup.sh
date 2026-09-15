#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/.config/swirldesk"
STATE="$ROOT/state"
mkdir -p "$STATE"

if ! command -v kreadconfig6 >/dev/null 2>&1; then
  echo 'kreadconfig6 not found.' >&2
  exit 1
fi

layout="$(kreadconfig6 --file kwinrc --group TabBox --key LayoutName 2>/dev/null || true)"
outline="$(kreadconfig6 --file kwinrc --group TabBox --key ShowOutline 2>/dev/null || true)"
highlight="$(kreadconfig6 --file kwinrc --group TabBox --key HighlightWindows 2>/dev/null || true)"

if [[ "$layout" != 'swirldesk_field_list' ]]; then
  printf '%s\n' "${layout:-thumbnail_grid}" > "$STATE/plasma_field_visual_prev_layout"
  printf '%s\n' "${outline:-true}" > "$STATE/plasma_field_visual_prev_outline"
  printf '%s\n' "${highlight:-true}" > "$STATE/plasma_field_visual_prev_highlight"
fi
