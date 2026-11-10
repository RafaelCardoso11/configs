#!/bin/bash
# searchable keybinds using vicinae dmenu
# Lists the live binds that carry a description; media/hardware (xf86) keys and
# the per-number workspace binds are left out and summarized instead.

{
  printf '%-28s %s\n' "SUPER + 1..3" "go to workspace" \
                      "SUPER + SHIFT + 1..3" "move window to workspace"
  hyprctl binds -j | jq -r '
    def bit($n): (.modmask / $n | floor) % 2 == 1;
    .[]
    | select(.has_description)
    | select(.key | test("^xf86"; "i") | not)
    | select(.description | test("^(NOTE|brackets)") | not)
    | [ (if bit(64) then "SUPER" else empty end),
        (if bit(4)  then "CTRL"  else empty end),
        (if bit(8)  then "ALT"   else empty end),
        (if bit(1)  then "SHIFT" else empty end),
        .key ]
      as $keys
    | "\($keys | join(" + "))\t\(.description)"' |
    awk -F'\t' '{ printf "%-28s %s\n", $1, $2 }'
} | vicinae dmenu -n "Keybinds" -p "Search keybinds..." --no-quick-look >/dev/null
