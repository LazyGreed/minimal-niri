#!/bin/bash

WAYBAR_CMD="waybar"

if pgrep -x "$WAYBAR_CMD" > /dev/null
then
    echo "Waybar is running. Killing process."
    pkill -x "$WAYBAR_CMD"
else
    echo "Waybar is not running. Starting process."
    nohup "$WAYBAR_CMD" &> /dev/null &
fi
