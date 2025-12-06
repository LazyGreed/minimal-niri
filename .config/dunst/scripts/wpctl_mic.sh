#!/usr/bin/bash

function get_volume {
    wpctl get-volume @DEFAULT_SOURCE@ | cut -d '.' -f 2 | sed 's/[^0-9]//g'
}

function is_mute {
    local volume_output=$(wpctl get-volume @DEFAULT_SOURCE@)
    
    if echo "$volume_output" | grep -q "\[MUTED\]"; then
        return 0
    else
        return 1
    fi
}

function send_notification {
    iconMuted="/usr/share/icons/kora/status/symbolic/audio-input-microphone-muted-symbolic.svg"

    if is_mute; then
        dunstify -i $iconMuted -r 2593 -u normal "muted"
    else
        volume=$(get_volume)
        if [ $volume -le 33 ]; then
            iconSound="/usr/share/icons/kora/status/symbolic/audio-input-microphone-low-symbolic.svg"
        else
            if [ $volume -le 66]; then
                iconSound="/usr/share/icons/kora/status/symbolic/audio-input-microphone-medium-symbolic.svg"
            else
                iconSound="/usr/share/icons/kora/status/symbolic/audio-input-microphone-high-symbolic.svg"
            fi
        fi

        bar=$(seq --separator="─" 0 "$((volume / 4))" | sed 's/[0-9]//g')
        ws=$(seq -s "─" $((volume / 4)) 25 | sed 's/[0-9]//g')
        dunstify -i $iconSound -r 2593 -u low " $bar   $ws   $volume%"
    fi
}

case $1 in
    up)
        wpctl set-mute @DEFAULT_SOURCE@ 0
        wpctl set-volume -l 1.0 @DEFAULT_SOURCE@ 10%+
        send_notification
    ;;
	down)        
        wpctl set-mute @DEFAULT_SOURCE@ 0
        wpctl set-volume -l 1.0 @DEFAULT_SOURCE@ 10%-
        send_notification
	;;
	toggle)
	    wpctl set-mute @DEFAULT_SOURCE@ toggle
		send_notification
	;;
esac
