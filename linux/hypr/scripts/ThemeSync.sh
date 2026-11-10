#!/bin/bash
# Makes the whole desktop follow the theme picked in vicinae ("Set Theme"):
# the matching wallust colorscheme is applied to waybar, kitty, hyprland borders,
# swaync, rofi, etc. Picking the "wallust" theme goes back to wallpaper colors.
# Started once from Startup_Apps.lua.

settings="$HOME/.config/vicinae/settings.json"
scriptsDir="$HOME/.config/hypr/scripts"

# vicinae theme id -> wallust built-in colorscheme
declare -A map=(
  [ayu-dark]=Ayu-Dark [ayu-mirage]=Ayu-Mirage
  [catppuccin-frappe]=Catppuccin-Frappé [catppuccin-latte]=Catppuccin-Latte
  [catppuccin-macchiato]=Catppuccin-Macchiato [catppuccin-mocha]=Catppuccin-Mocha
  [dracula]=Dracula [elementary-dark]=Elementary
  [gruvbox-dark]=Gruvbox-Dark [gruvbox-light]=Gruvbox-Material-Light
  [kanagawa]=Kanagawa-Wave [nord]=Nord [nord-light]=Nord-Light [one-dark]=One-Dark
  [rose-pine]=rose-pine [rose-pine-dawn]=rose-pine-dawn [rose-pine-moon]=rose-pine-moon
  [solarized-dark]=solarized-dark [solarized-light]=solarized-light
  [tokyo-night]=Tokyo-Night [tokyo-night-storm]=Tokyo-Night-Storm
)

current_theme() {
  grep -v '^//' "$settings" | jq -r '.theme.dark.name // empty' 2>/dev/null
}

apply() {
  local theme=$1
  if [[ $theme == wallust ]]; then
    # a wallpaper change already ran wallust and switched vicinae here; don't redo it
    local generated="$HOME/.local/share/vicinae/themes/wallust.toml"
    (( $(date +%s) - $(stat -c %Y "$generated") < 15 )) && return
    "$scriptsDir/WallustSwww.sh"
  elif [[ -n ${map[$theme]} ]]; then
    wallust theme "${map[$theme]}" -s || return
  else
    return  # no matching colorscheme: leave the rest of the desktop as is
  fi
  sleep 1
  hyprctl reload >/dev/null
  pkill -SIGUSR1 kitty
  "$scriptsDir/Refresh.sh" >/dev/null 2>&1
}

last=$(current_theme)
# ponytail: polls every 2s (no inotify-tools installed); switch to inotifywait if it ever matters
while sleep 2; do
  now=$(current_theme)
  if [[ -n $now && $now != "$last" ]]; then
    if [[ -f "${XDG_RUNTIME_DIR:-/tmp}/hypr-presentation" ]]; then
      # theme is locked during presentation mode: put the previous one back
      vicinae theme set "$last" >/dev/null 2>&1
      notify-send -u critical -t 3000 -a "Presentation" "Theme locked" "Turn off presentation mode (SUPER+P) to change it"
      continue
    fi
    apply "$now"
  fi
  last=$now
done
