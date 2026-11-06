#!/bin/bash
# Waybar JSON for the presentation-mode toggle (SUPER+P)
if [[ -f "${XDG_RUNTIME_DIR:-/tmp}/hypr-presentation" ]]; then
  jq -cn '{text: "", class: "on", tooltip: "Presentation mode: on (click to turn off)"}'
else
  jq -cn '{text: "", class: "off", tooltip: "Presentation mode: off (click to turn on)"}'
fi
