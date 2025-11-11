#!/usr/bin/bash

function get_volume {
    wpctl get-volume @DEFAULT_SINK@ | cut -d '.' -f 2 | sed 's/[^0-9]//g'
}

function is_mute {
    local volume_output=$(wpctl get-volume @DEFAULT_SINK@)
    
    if echo "$volume_output" | grep -q "\[MUTED\]"; then
        return 0
    else
        return 1
    fi
}

function send_notification {
    iconSound="/usr/share/icons/candy-icons/status/scalable/audio-volume-high.svg"
    iconMuted="/usr/share/icons/candy-icons/status/scalable/audio-volume-muted.svg"

    if is_mute; then
        dunstify -i $iconMuted -r 2593 -u normal "muted"
    else
        volume=$(get_volume)
        if [ $volume == 00 ]; then
    		bar=$(seq --separator="─" 0 33 | sed 's/[0-9]//g')
        else
    		bar=$(seq --separator="─" 0 "$((volume / 3))" | sed 's/[0-9]//g')
        fi
        dunstify -i $iconSound -r 2593 -u normal " $bar"
    fi
}

case $1 in
    up)
        wpctl set-mute @DEFAULT_SINK@ 0
        wpctl set-volume -l 1.0 @DEFAULT_SINK@ 2%+
        send_notification
    ;;
	down)        
        wpctl set-mute @DEFAULT_SINK@ 0
        wpctl set-volume -l 1.0 @DEFAULT_SINK@ 2%-
        send_notification
	;;
	toggle)
	    wpctl set-mute @DEFAULT_SINK@ toggle
		send_notification
	;;
esac
