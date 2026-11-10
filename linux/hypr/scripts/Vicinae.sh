#!/bin/bash
# Drop-in for `vicinae ...` that always opens on the main monitor.
# vicinae's launcher_window.screen only works on X11; on Wayland the layer surface
# lands on the focused monitor, so focus the main one first.
MAIN_MONITOR="DP-3"

hyprctl dispatch "hl.dsp.focus({ monitor = \"$MAIN_MONITOR\" })" >/dev/null
exec vicinae "$@"
