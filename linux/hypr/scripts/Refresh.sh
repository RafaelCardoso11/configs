#!/bin/bash
# Scripts for refreshing ags, waybar, rofi, swaync, wallust

SCRIPTSDIR=$HOME/.config/hypr/scripts


# Kill already running processes
_ps=(waybar swaync ags)
for _prs in "${_ps[@]}"; do
    if pidof "${_prs}" >/dev/null; then
        pkill "${_prs}"
    fi
done

# added since wallust sometimes not applying
killall -SIGUSR2 waybar 

# quit ags & relaunch ags
ags -q && ags &

# some process to kill
for pid in $(pidof waybar swaync ags swaybg); do
    kill -SIGUSR1 "$pid"
done

#Restart waybar
sleep 1
waybar &

# relaunch swaync
sleep 0.5
swaync > /dev/null 2>&1 &
# reload swaync
swaync-client --reload-config


exit 0