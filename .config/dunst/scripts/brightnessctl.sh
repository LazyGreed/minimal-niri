#!/usr/bin/bash

function get_brightness {
    brightnessctl info | grep Current | cut -d '(' -f 2 | tr '%)' ' '
}

function send_notification {
    icon="/usr/share/icons/candy-icons/preferences/scalable/preferences-desktop-display.svg"
    brightness=$(get_brightness)
    bar=$(seq -s "─" 0 $((brightness / 3)) | sed 's/[0-9]//g')
    
    dunstify -i "$icon" -r 5555 -u low " $bar"
}

case $1 in
    up)
        brightnessctl set +5% 
        send_notification
    ;;
    down)
        brightnessctl set 5%-
        send_notification
    ;;
esac
