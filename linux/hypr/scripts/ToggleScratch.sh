#!/bin/bash
# SUPER+U: show a dedicated "scratch" workspace (only wallpaper + its own windows)
# on the current monitor, and go back to the exact workspace you came from.
# A regular workspace is used instead of a special one because special
# workspaces are drawn on top of the current workspace's windows.

state="${XDG_RUNTIME_DIR:-/tmp}/hypr-scratch-return"
current=$(hyprctl activeworkspace -j | jq -r .name)

if [[ $current == scratch ]]; then
  target=$(cat "$state" 2>/dev/null)
  hyprctl dispatch "hl.dsp.focus({ workspace = \"${target:-1}\", on_current_monitor = true })" >/dev/null
else
  echo "$current" > "$state"
  hyprctl dispatch 'hl.dsp.focus({ workspace = "name:scratch", on_current_monitor = true })' >/dev/null
fi
