#!/usr/bin/env bash

windows=$(niri msg --json windows)
choice=$(echo "$windows" | jq -r '.[] | "\(.title) ( \(.app_id) )\u0000icon\u001f\(.app_id)"' | fuzzel -d --index)

[ -z "$choice" ] && exit 0

id=$(echo "$windows" | jq -r ".[$choice].id")
niri msg action focus-window --id "$id"
