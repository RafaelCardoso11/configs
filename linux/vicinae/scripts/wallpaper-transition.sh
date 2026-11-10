#!/bin/bash
# @vicinae.schemaVersion 1
# @vicinae.title Wallpaper Transition
# @vicinae.mode silent
# @vicinae.packageName Arch
# @vicinae.icon /usr/share/icons/WhiteSur/apps/scalable/preferences-desktop-wallpaper.svg
# @vicinae.keywords ["transicao", "wallpaper", "swww", "animation"]

setsid "$HOME/.config/hypr/scripts/WallpaperTransition.sh" >/dev/null 2>&1 &
