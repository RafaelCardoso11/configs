#!/bin/bash
# Pick a Hyprland animation preset (vicinae menu); it is copied over UserAnimations.lua

animations_dir="$HOME/.config/hypr/animations"
target="$HOME/.config/hypr/UserConfigs/UserAnimations.lua"

choice=$(find -L "$animations_dir" -maxdepth 1 -type f -name '*.lua' -printf '%f\n' | sed 's/\.lua$//' | sort -V |
  vicinae dmenu -n "Animations" -p "Search animation presets..." --no-section --no-quick-look)

[[ -n $choice && -f "$animations_dir/$choice.lua" ]] || exit 0
cp "$animations_dir/$choice.lua" "$target"
hyprctl reload >/dev/null
notify-send -a "Animations" "$choice" "Hyprland animation loaded"
