#!/bin/bash
# Wallust Colors for current wallpaper

# Initialize a flag to determine if the ln command was executed
ln_success=false

# Get current focused monitor
current_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

# Ask the daemon what the focused monitor shows; awww keeps no per-monitor path file
wallpaper_path=$(swww query | awk -F'image: ' -v m="$current_monitor" '$0 ~ ": "m":" {print $2}')

if [ -f "$wallpaper_path" ]; then
    echo $wallpaper_path
    # copy the wallpaper for wallpaper effects and the lock screen
	cp -r "$wallpaper_path" "$HOME/.config/hypr/wallpaper_effects/.wallpaper_current" && ln_success=true
fi

# Check the flag before executing further commands
# A theme picked in vicinae (anything but "wallust") wins over wallpaper colors
vicinae_theme=$(grep -v '^//' "$HOME/.config/vicinae/settings.json" | jq -r '.theme.dark.name // "wallust"' 2>/dev/null)

if [ "$ln_success" = true ] && [ "$vicinae_theme" = wallust ]; then
    # execute wallust
	echo 'about to execute wallust'
    # execute wallust skipping tty and terminal changes
    # vicinae only rescans themes on directory changes, so the regenerated file is
    # swapped in with mv instead of being rewritten in place
    theme_file="$HOME/.local/share/vicinae/themes/wallust.toml"
    { wallust run "$wallpaper_path" -s &&
      cp "$theme_file" "$theme_file.tmp" && mv -f "$theme_file.tmp" "$theme_file" &&
      sleep 0.3 && vicinae theme set wallust >/dev/null 2>&1; } &
fi
