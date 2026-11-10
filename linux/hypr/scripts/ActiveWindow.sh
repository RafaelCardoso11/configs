#!/bin/bash
# Waybar: name of the focused app, macOS-style.
# Replaces hyprland/window, which reads the monitor's normal workspace and so shows
# "Desktop" while the focused window lives in a special workspace (scratchpad).

name() {
  case "$1" in
    "") echo "Desktop" ;;
    brave-browser) echo "Brave" ;;
    kitty) echo "Terminal" ;;
    thunar) echo "Files" ;;
    code) echo "VS Code" ;;
    *.*.*) echo "${1##*.}" ;; # reverse-DNS app ids: org.gnome.Nautilus -> Nautilus
    *) echo "$1" ;;
  esac
}

name "$(hyprctl activewindow -j | jq -r '.class // ""')"
# read in this shell (not a pipeline subshell) so the trap can stop nc when waybar kills us on reload
exec 3< <(nc -U "$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock")
nc_pid=$!
trap 'kill $nc_pid 2>/dev/null' EXIT
trap 'exit' TERM INT HUP
while read -r event <&3; do
  case "$event" in
    activewindow\>\>*)
      # activewindow>>CLASS,TITLE (empty class when focus leaves all windows)
      payload="${event#activewindow>>}"
      name "${payload%%,*}"
      ;;
  esac
done
