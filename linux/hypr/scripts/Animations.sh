#!/bin/bash
# Pick a Hyprland animation preset (vicinae menu); it is copied over UserAnimations.conf

animations_dir="$HOME/.config/hypr/animations"
target="$HOME/.config/hypr/UserConfigs/UserAnimations.conf"

choice=$(find -L "$animations_dir" -maxdepth 1 -type f -name '*.conf' -printf '%f\n' | sed 's/\.conf$//' | sort -V |
  vicinae dmenu -n "Animations" -p "Search animation presets..." --no-section --no-quick-look)

[[ -n $choice && -f "$animations_dir/$choice.conf" ]] || exit 0
cp "$animations_dir/$choice.conf" "$target"
hyprctl reload >/dev/null
notify-send -a "Animations" "$choice" "Hyprland animation loaded"
