#!/bin/bash

song_info=$(playerctl metadata xesam:title)

echo "$song_info" 
