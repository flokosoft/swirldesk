#!/usr/bin/env bash

if command -v fuzzel >/dev/null 2>&1; then
    fuzzel
elif command -v rofi >/dev/null 2>&1; then
    rofi -show drun
elif command -v tofi-drun >/dev/null 2>&1; then
    tofi-drun
else
    echo "Kein Launcher gefunden"
fi
