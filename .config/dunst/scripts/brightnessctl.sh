#!/usr/bin/bash

function get_brightness {
    brightnessctl info | grep Current | cut -d '(' -f 2 | cut -d '%' -f 1
}

function send_notification {
    # icon="/usr/share/icons/kora/status/symbolic/brightness-symbolic.svg"
    brightness=$(get_brightness)
    if [ $brightness -le 33 ]; then
        icon="/usr/share/icons/kora/status/symbolic/brightness-low-symbolic.svg"
    else
        if [ $brightness -le 66 ]; then
            icon="/usr/share/icons/kora/status/symbolic/brightness-medium-symbolic.svg"
        else
            icon="/usr/share/icons/kora/status/symbolic/brightness-high-symbolic.svg"
        fi
    fi

    bar=$(seq -s "─" 0 $((brightness / 4)) | sed 's/[0-9]//g')
    ws=$(seq -s "─" $((brightness / 4)) 25 | sed 's/[0-9]//g')
    
    dunstify -i "$icon" -r 5555 -u low " $bar   $ws   $brightness%"
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
