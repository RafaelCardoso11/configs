#!/bin/bash
# Apply the WhiteSur (macOS) GTK + icon theme for a mode: GtkTheme.sh Dark|Light
# Called by DarkLight.sh; safe to run on its own.

mode="${1:-Dark}"
lower="${mode,,}"
theme="WhiteSur-$mode"
icons="WhiteSur-$lower"

# GTK3 (Wayland reads gsettings; settings.ini covers apps that read the file)
gsettings set org.gnome.desktop.interface color-scheme "prefer-$lower"
gsettings set org.gnome.desktop.interface gtk-theme "$theme"
gsettings set org.gnome.desktop.interface icon-theme "$icons"
ini="$HOME/.config/gtk-3.0/settings.ini"
sed -i "s|^gtk-theme-name=.*|gtk-theme-name=$theme|; s|^gtk-icon-theme-name=.*|gtk-icon-theme-name=$icons|" "$ini"
sed -i "s|^gtk-application-prefer-dark-theme=.*|gtk-application-prefer-dark-theme=$([[ $mode == Dark ]] && echo 1 || echo 0)|" "$ini"

# GTK4 / libadwaita ignore gtk-theme; they only load ~/.config/gtk-4.0/gtk.css.
# WhiteSur ships that css inside a gresource with relative asset urls, so extract it once per mode.
src="/usr/share/themes/$theme/gtk-4.0/gtk.gresource"
out="$HOME/.local/share/whitesur-gtk4/$mode"
if [[ ! -f "$out/gtk.css" && -f "$src" ]]; then
  for res in $(gresource list "$src"); do
    file="$out/${res#/org/gnome/theme/}"
    mkdir -p "$(dirname "$file")"
    gresource extract "$src" "$res" > "$file"
  done
fi
mkdir -p "$HOME/.config/gtk-4.0"
for f in gtk.css gtk-dark.css assets; do
  [[ -e "$out/$f" ]] && ln -sfn "$out/$f" "$HOME/.config/gtk-4.0/$f"
done

# Qt apps (qt5ct/qt6ct) only take the icons
for conf in "$HOME/.config/qt5ct/qt5ct.conf" "$HOME/.config/qt6ct/qt6ct.conf"; do
  [[ -f "$conf" ]] && sed -i "s|^icon_theme=.*|icon_theme=$icons|" "$conf"
done
