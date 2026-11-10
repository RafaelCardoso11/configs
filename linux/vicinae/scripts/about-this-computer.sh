#!/bin/bash
# @vicinae.schemaVersion 1
# @vicinae.title About This Computer
# @vicinae.mode fullOutput
# @vicinae.packageName Arch
# @vicinae.icon /usr/share/icons/WhiteSur/apps/scalable/hwinfo.svg
# @vicinae.keywords ["sobre", "about", "sistema", "fastfetch", "info"]

# pad by characters, not bytes, so accented labels line up
row() { printf '  %s%*s %s\n' "$1" $((14 - ${#1})) '' "$2"; }
gpu=$(lspci | grep -iE 'vga|3d' | sed 's/.*: //; s/ (rev.*//' | head -1)
displays=$(hyprctl monitors -j | jq -r 'map("\(.width)x\(.height)") | join(" + ")')

printf '\n  Arch Linux\n  %s\n\n' "$(cat /sys/class/dmi/id/product_name 2>/dev/null)"
row "Computer" "$(hostnamectl hostname)"
row "Processor" "$(lscpu | sed -n 's/^Model name: *//p')"
row "Graphics" "$gpu"
row "Memory" "$(free -h | awk '/^Mem:/ {print $2}') ($(free -h | awk '/^Mem:/ {print $3}') in use)"
row "Disk /" "$(df -h / | awk 'NR==2 {print $4 " free of " $2}')"
row "Disk /home" "$(df -h /home | awk 'NR==2 {print $4 " free of " $2}')"
row "Displays" "$displays"
row "Kernel" "$(uname -r)"
row "Hyprland" "$(hyprctl version -j | jq -r .tag)"
row "Packages" "$(pacman -Qq | wc -l)"
row "Uptime" "$(uptime -p | sed 's/^up //')"
