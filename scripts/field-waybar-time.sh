#!/usr/bin/env bash
set -u

local_time=$(date '+%H:%M')
local_date=$(date '+%a %d %b %Y')
local_zone=$(date '+%Z (%z)')
zulu_time=$(TZ=UTC date '+%H:%MZ')
zulu_date=$(TZ=UTC date '+%d %b %Y')

printf '{"text":"%s L","tooltip":"LOCAL  %s  //  %s\\nZONE   %s\\nZULU   %s  //  %s","class":"local"}\n' \
    "$local_time" "$local_time" "$local_date" "$local_zone" "$zulu_time" "$zulu_date"
