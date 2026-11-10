#!/bin/bash
# Terminal theme picker (vicinae "Terminal Theme"): zsh prompt (Starship or an oh-my-zsh theme)
# and kitty color palette, in one searchable list.

zshrc="$HOME/.zshrc"
kitty_conf="$HOME/.config/kitty/kitty.conf"
kitty_themes="$HOME/.config/kitty/kitty-themes"
omz_themes="$HOME/.oh-my-zsh/themes"
iDIR="$HOME/.config/swaync/images"

# empty ZSH_THEME = Starship (see ~/.zshrc)
prompt=$(sed -n 's/^ZSH_THEME="\(.*\)"/\1/p' "$zshrc")
prompt=${prompt:-Starship}
colors=$(sed -n 's|^include ./kitty-themes/\(.*\)\.conf|\1|p' "$kitty_conf")

choice=$({
  echo "Prompt · Starship"
  find -L "$omz_themes" -name '*.zsh-theme' -printf '%f\n' | sed 's/\.zsh-theme$//' | sort | sed 's/^/Prompt · /'
  find -L "$kitty_themes" -name '*.conf' -printf '%f\n' | sed 's/\.conf$//' | sort | sed 's/^/Colors · /'
} | "$HOME/.config/hypr/scripts/Vicinae.sh" dmenu -n "Terminal Theme" -p "Search prompts and colors..." \
  -s "Current: $prompt · $colors" --no-quick-look)

case "$choice" in
  "Prompt · "*)
    theme="${choice#Prompt · }"
    [[ "$theme" == Starship ]] && value="" || value="$theme"
    # ~/.zshrc is a symlink into the configs repo; plain sed -i would replace it with a copy
    sed -i --follow-symlinks "s|^ZSH_THEME=.*|ZSH_THEME=\"$value\"|" "$zshrc"
    notify-send -u low -i "$iDIR/ja.png" "Prompt: $theme" "Applies to new terminals (or run: exec zsh)"
    ;;
  "Colors · "*)
    theme="${choice#Colors · }"
    sed -i "s|^include ./kitty-themes/.*|include ./kitty-themes/$theme.conf|" "$kitty_conf"
    # these come after the include and would override the palette; DarkLight.sh only
    # rewrites them while they are uncommented, so a picked palette stays in charge
    sed -i -E 's/^(foreground|background|cursor) /# &/' "$kitty_conf"
    pkill -SIGUSR1 -x kitty
    notify-send -u low -i "$iDIR/ja.png" "Kitty colors: $theme" "Applied to open terminals"
    ;;
esac
