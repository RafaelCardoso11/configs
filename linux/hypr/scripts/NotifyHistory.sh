#!/bin/bash
# Recent notifications in vicinae, newest first; picking one copies it

log="$HOME/.cache/notify-history"
[ -f "$log" ] || touch "$log"

# keep the log bounded
tail -n 500 "$log" > "$log.tmp" && mv -f "$log.tmp" "$log"

choice=$(tac "$log" | vicinae dmenu -n "Notifications" -p "Search notifications..." --no-section --no-quick-look)
[ -n "$choice" ] && printf '%s' "$choice" | wl-copy
