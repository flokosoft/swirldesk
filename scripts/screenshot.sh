#!/usr/bin/env bash

mkdir -p "$HOME/Bilder/Screenshots"

grim -g "$(slurp)" "$HOME/Bilder/Screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png"
