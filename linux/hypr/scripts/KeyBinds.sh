#!/bin/bash
# searchable keybinds using vicinae dmenu
# Only commented binds are listed; media/hardware (xf86) keys and the
# per-number workspace binds are left out and summarized instead.

hypr="$HOME/.config/hypr"
files=("$hypr/configs/Keybinds.conf" "$hypr/UserConfigs/UserKeybinds.conf" "$hypr/UserConfigs/Laptops.conf")

{
  printf '%-28s %s\n' "SUPER + 1..0" "go to workspace" \
                      "SUPER + SHIFT + 1..0" "move window to workspace"
  cat "${files[@]}" 2>/dev/null |
    grep -E '^bind' | grep -v xf86 | grep '#' | grep -vE '# *(NOTE|brackets)' |
    sed -E 's/^bind[a-z]* *= *//; s/\$mainMod/SUPER/g' |
    awk -F'#' '{
      split($1, p, ","); mods = p[1]; key = p[2]; desc = $2
      gsub(/^ +| +$/, "", mods); gsub(/^ +| +$/, "", key); gsub(/^ +| +$/, "", desc)
      gsub(/ +/, " + ", mods)
      printf "%-28s %s\n", (mods == "" ? key : mods " + " key), desc
    }'
} | vicinae dmenu -n "Keybinds" -p "Search keybinds..." --no-quick-look >/dev/null
