#!/usr/bin/env bash

current_wallpaper=$(swww query | sed -n 's/.*image: \(.*\)/\1/p')

if [ -z "$current_wallpaper" ]; then
    echo "Error: Could not retrieve current wallpaper" >&2
    exit 1
fi

if [ ! -f "$current_wallpaper" ]; then
    echo "Error: Wallpaper file does not exist: $current_wallpaper" >&2
    exit 1
fi

cp "$current_wallpaper" ~/.config/hypr/current_wallpaper

hyprlock

