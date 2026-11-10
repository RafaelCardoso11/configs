#!/bin/bash
# Restart waybar and reload swaync after a theme / wallpaper change.
# Waits for the old bar to exit before starting a new one, so repeated calls never stack bars.

pkill -x waybar
while pgrep -x waybar >/dev/null; do sleep 0.1; done
setsid waybar >/dev/null 2>&1 &

if pgrep -x swaync >/dev/null; then
    swaync-client --reload-config --reload-css >/dev/null 2>&1
else
    setsid swaync >/dev/null 2>&1 &
fi

exit 0
