#!/bin/bash
# Waybar JSON for the Arch logo: icon plus a system summary tooltip
mem=$(free -h | awk '/^Mem:/ {print $3 " / " $2}')
tip="$(hostnamectl hostname)
Arch Linux · kernel $(uname -r)
Hyprland $(hyprctl version -j | jq -r .tag)
Up $(uptime -p | sed 's/^up //')
Memory: $mem
Packages: $(pacman -Qq | wc -l)"
jq -cn --arg t "$tip" '{text: "", tooltip: $t}'
