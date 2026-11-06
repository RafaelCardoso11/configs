#!/bin/bash
# Waybar JSON for the light/dark toggle: moon in dark mode, sun in light mode
if [[ $(cat "$HOME/.cache/.theme_mode" 2>/dev/null) == Light ]]; then
  jq -cn --arg t "$(printf '\U000f05a8')" '{text: $t, class: "light", tooltip: "Light mode (click for dark)"}'
else
  jq -cn --arg t "$(printf '\U000f0594')" '{text: $t, class: "dark", tooltip: "Dark mode (click for light)"}'
fi
