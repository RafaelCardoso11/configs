#!/bin/bash
# SUPER+P: screen-sharing mode. Swaps every monitor to a neutral wallpaper and
# turns on Do Not Disturb; running it again restores the previous wallpapers
# and notifications. Colors/theme are left untouched on purpose.

state="${XDG_RUNTIME_DIR:-/tmp}/hypr-presentation"
# Arch wallpaper matching the current light/dark mode (kept by DarkLight.sh)
if [[ $(cat "$HOME/.cache/.theme_mode" 2>/dev/null) == Light ]]; then
  neutral="$HOME/Pictures/wallpapers/aesthetic/arch-nord-light.png"
else
  neutral="$HOME/Pictures/wallpapers/aesthetic/arch-nord-dark.png"
fi
params=(--transition-type fade --transition-duration 0.6)

if [[ -f $state ]]; then
  # each saved line: "<monitor> <image path>"
  while read -r mon img; do
    [[ -f $img ]] && swww img -o "$mon" "$img" "${params[@]}"
  done < "$state"
  rm -f "$state"
  swaync-client -df >/dev/null
  notify-send -a "Presentation" "Presentation mode off" "Wallpaper and notifications restored"
else
  swww query | sed -nE 's/^: ([^:]+):.*image: (.*)$/\1 \2/p' > "$state"
  swaync-client -dn >/dev/null
  swww img "$neutral" "${params[@]}"
fi

# refresh the bar indicator
pkill -RTMIN+8 waybar
