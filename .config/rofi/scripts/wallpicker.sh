#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
WALLTHEME="$HOME/.config/rofi/theme/wallselect.rasi"
ROFI_OPTIONS="-dmenu -i -p Wallpaper -theme $WALLTHEME"
SWWW_OPTIONS="--transition-type random --transition-fps 60"

if ! pgrep -x "swww-daemon" > /dev/null; then
    echo "swww-daemon is not running. Starting it now..."
    swww-daemon &
    sleep 1 
fi

WALLPAPER_PATH=$(
    find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) 2>/dev/null |
    sed "s|^$WALLPAPER_DIR/||" |
    rofi $ROFI_OPTIONS
)

if [ -z "$WALLPAPER_PATH" ]; then
    echo "Wallpaper selection cancelled or no wallpapers found."
    exit 0
fi

FULL_WALLPAPER_PATH="$WALLPAPER_DIR/$WALLPAPER_PATH"

if [ -f "$FULL_WALLPAPER_PATH" ]; then
    echo "Setting wallpaper: $FULL_WALLPAPER_PATH"
    swww img "$FULL_WALLPAPER_PATH" $SWWW_OPTIONS
    matugen image "$FULL_WALLPAPER_PATH"

else
    echo "Error: Selected file does not exist: $FULL_WALLPAPER_PATH"
    exit 1
fi

exit 0

