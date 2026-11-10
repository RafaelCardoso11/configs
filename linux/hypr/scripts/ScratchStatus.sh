#!/bin/bash
# Waybar: Ⓢ next to the workspace numbers, lit while a scratch is in use (SUPER+U or SUPER+minus).
# hyprland/workspaces can't do it: Hyprland 0.57 reports named workspaces with id null,
# so waybar never marks them active.

print() {
  local class=""
  # lit for either scratch: the "scratch" workspace (SUPER+U) or the special scratchpad shown on the focused monitor (SUPER+minus)
  if [[ "$(hyprctl activeworkspace -j | jq -r .name)" == scratch ]] ||
    [[ -n "$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .specialWorkspace.name')" ]]; then
    class="active"
  fi
  jq -cn --arg c "$class" '{text: "<span size=\"72%\" rise=\"1pt\">Ⓢ</span>", class: $c, tooltip: "Scratch (SUPER+U / SUPER+minus)"}'
}

print
# read in this shell (not a pipeline subshell) so the trap can stop nc when waybar kills us on reload
exec 3< <(nc -U "$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock")
nc_pid=$!
trap 'kill $nc_pid 2>/dev/null' EXIT
trap 'exit' TERM INT HUP
while read -r event <&3; do
  case "$event" in
    workspace\>\>* | focusedmon\>\>* | activespecial\>\>*) print ;;
  esac
done
