#!/bin/bash
# Close vicinae when another monitor gets focus while it is open.
# close_on_focus_loss covers clicks on the same monitor, but a click on another monitor only
# emits focusedmon: keyboard focus stays on vicinae's layer, so it never sees a focus loss.
# Started once from Startup_Apps.lua.

open_on=""
# read in this shell (not a pipeline subshell) so the trap can stop nc when we exit
exec 3< <(nc -U "$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock")
nc_pid=$!
trap 'kill $nc_pid 2>/dev/null' EXIT
trap 'exit' TERM INT HUP
while read -r event <&3; do
  case "$event" in
    openlayer\>\>vicinae)
      open_on=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
      ;;
    closelayer\>\>vicinae)
      open_on=""
      ;;
    focusedmon\>\>*)
      mon="${event#focusedmon>>}"
      mon="${mon%%,*}"
      if [[ -n "$open_on" && "$mon" != "$open_on" ]]; then
        vicinae close >/dev/null 2>&1
        open_on=""
      fi
      ;;
  esac
done
