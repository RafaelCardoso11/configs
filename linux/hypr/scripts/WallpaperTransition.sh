#!/bin/bash
# Pick the swww/awww transition used when changing wallpaper (SUPER+W)

conf="$HOME/.config/hypr/wallpaper-transition"

choice=$(cat <<'LIST' | "$HOME/.config/hypr/scripts/Vicinae.sh" dmenu -n "Wallpaper Transition" -p "Search transitions..." --no-section --no-quick-look
fade      smooth dissolve (macOS-like)
simple    plain dissolve
left      slide in from the left
right     slide in from the right
top       slide in from the top
bottom    slide in from the bottom
wipe      diagonal line sweep
wave      wavy line sweep
center    circle growing from the center
any       circle growing from a random point
outer     circle shrinking to the center
random    a different one every time
none      instant, no animation
LIST
)

type=${choice%% *}
[[ -n $type ]] || exit 0
echo "$type" > "$conf"
notify-send -a "Wallpaper" "Transition: $type" "Used on the next wallpaper change"
