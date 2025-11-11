#!/bin/bash

WALLSELECT_THEME="$HOME/.config/rofi/theme/wallselect.rasi"
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "Error: Wallpaper directory $WALLPAPER_DIR does not exist"
    exit 1
fi

wallpapers=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.gif" \) | sort)
if [ -z "$wallpapers" ]; then
    echo "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

display_names=""
while IFS= read -r wallpaper; do
    filename=$(basename "$wallpaper")
    name_without_ext="${filename%.*}"
    display_names+="$name_without_ext"$'\n'
done <<< "$wallpapers"
display_names=${display_names%$'\n'}

selected=$(echo "$display_names" | rofi -dmenu -theme "$WALLSELECT_THEME" -p "Select Wallpaper")
if [ -z "$selected" ]; then
    exit 0
fi

img_path=""
while IFS= read -r wallpaper; do
    filename=$(basename "$wallpaper")
    name_without_ext="${filename%.*}"
    if [ "$name_without_ext" = "$selected" ]; then
        img_path="$wallpaper"
        break
    fi
done <<< "$wallpapers"

if [ -n "$img_path" ]; then
    swww img "$img_path" --transition-type random --transition-fps 60
    matugen image "$img_path"
else
    echo "Error: Could not find wallpaper file for selection: $selected"
    exit 1
fi
