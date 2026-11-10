#!/bin/bash
# Wallpaper is locked while presentation mode (SUPER+P) is on
if [ -f "${XDG_RUNTIME_DIR:-/tmp}/hypr-presentation" ]; then
  notify-send -u critical -t 3000 -a "Presentation" "Wallpaper locked" "Turn off presentation mode (SUPER+P) to change it"
  exit 0
fi

# Applies the wallpaper given as $1 (picked in the vicinae "Select Wallpaper" grid, SUPER W)

# WALLPAPERS PATH
terminal=kitty
wallDIR="$HOME/Pictures/wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"

# Directory for swaync
iDIR="$HOME/.config/swaync/images"
iDIRi="$HOME/.config/swaync/icons"

# swww transition config
FPS=60
# chosen with WallpaperTransition.sh (vicinae "Wallpaper Transition"); "any" if never set
TYPE=$(cat "$HOME/.config/hypr/wallpaper-transition" 2>/dev/null || echo any)
DURATION=2
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

# Check if package bc exists
if ! command -v bc &>/dev/null; then
  notify-send -i "$iDIR/error.png" "bc missing" "Install package bc first"
  exit 1
fi

# Variables
focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

# Ensure focused_monitor is detected
if [[ -z "$focused_monitor" ]]; then
  notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Could not detect focused monitor"
  exit 1
fi

# Monitor details
scale_factor=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .scale')
monitor_height=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .height')


# Kill existing wallpaper daemons for video
kill_wallpaper_for_video() {
  swww kill 2>/dev/null
  pkill mpvpaper 2>/dev/null
  pkill swaybg 2>/dev/null
  pkill hyprpaper 2>/dev/null
}

# Kill existing wallpaper daemons for image
kill_wallpaper_for_image() {
  pkill mpvpaper 2>/dev/null
  pkill swaybg 2>/dev/null
  pkill hyprpaper 2>/dev/null
}

# Offer SDDM Sequioa Wallpaper Option (only for non-video wallpapers)
set_sddm_wallpaper() {
  sleep 1
  sddm_sequoia="/usr/share/sddm/themes/sequoia_2"

  if [ -d "$sddm_sequoia" ]; then

    # Check if yad is running to avoid multiple notifications
    if pidof yad >/dev/null; then
      killall yad
    fi

    if yad --info --text="Set current wallpaper as SDDM background?\n\nNOTE: This only applies to SEQUOIA SDDM Theme" \
      --text-align=left \
      --title="SDDM Background" \
      --timeout=5 \
      --timeout-indicator=right \
      --button="yes:0" \
      --button="no:1"; then

      # Check if terminal exists
      if ! command -v "$terminal" &>/dev/null; then
        notify-send -i "$iDIR/error.png" "Missing $terminal" "Install $terminal to enable setting of wallpaper background"
        exit 1
      fi

      # Open terminal to enter password
      $terminal -e bash -c "echo 'Enter your password to set wallpaper as SDDM Background'; \
            sudo cp -r $wallpaper_current '$sddm_sequoia/backgrounds/default' && \
            notify-send -i '$iDIR/ja.png' 'SDDM' 'Background SET'"
    fi
  fi
}

modify_startup_config() {
  local selected_file="$1"
  local startup_config="$HOME/.config/hypr/UserConfigs/Startup_Apps.lua"

  # Startup_Apps.lua starts mpvpaper when livewallpaper is set, swww-daemon when it is empty
  if [[ "$selected_file" =~ \.(mp4|mkv|mov|webm)$ ]]; then
    # Lua long string: the path is written verbatim, no escaping needed
    LW="$selected_file" awk '/^local livewallpaper = /{ print "local livewallpaper = [==[" ENVIRON["LW"] "]==]"; next } 1' \
      "$startup_config" > "$startup_config.tmp" && mv "$startup_config.tmp" "$startup_config"
    echo "Configured for live wallpaper (video)."
  else
    sed -i 's|^local livewallpaper = .*|local livewallpaper = ""|' "$startup_config"
    echo "Configured for static wallpaper (image)."
  fi
}

# Apply Image Wallpaper
apply_image_wallpaper() {
  local image_path="$1"

  kill_wallpaper_for_image

  if ! pgrep -x "swww-daemon" >/dev/null; then
    echo "Starting swww-daemon..."
    swww-daemon --format xrgb &
  fi

  swww img "$image_path" $SWWW_PARAMS

  # Run additional scripts
  "$SCRIPTSDIR/WallustSwww.sh"
  sleep 2
  "$SCRIPTSDIR/Refresh.sh"
  sleep 1

  set_sddm_wallpaper
}

apply_video_wallpaper() {
  local video_path="$1"

  # Check if mpvpaper is installed
  if ! command -v mpvpaper &>/dev/null; then
    notify-send -i "$iDIR/error.png" "E-R-R-O-R" "mpvpaper not found"
    return 1
  fi
  kill_wallpaper_for_video

  # Apply video wallpaper using mpvpaper
  mpvpaper '*' -o "load-scripts=no no-audio --loop" "$video_path" &
}

# Main function
main() {
  selected_file="$1"

  if [[ ! -f "$selected_file" ]]; then
    notify-send -i "$iDIR/error.png" "Wallpaper not found" "$selected_file"
    exit 1
  fi

  # Modify the Startup_Apps.lua file based on wallpaper type
  modify_startup_config "$selected_file"

  # **CHECK FIRST** if it's a video or an image **before calling any function**
  if [[ "$selected_file" =~ \.(mp4|mkv|mov|webm|MP4|MKV|MOV|WEBM)$ ]]; then
    apply_video_wallpaper "$selected_file"
  else
    apply_image_wallpaper "$selected_file"
  fi
}

main "$1"

