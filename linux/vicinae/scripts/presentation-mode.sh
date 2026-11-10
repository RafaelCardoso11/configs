#!/bin/bash
# @vicinae.schemaVersion 1
# @vicinae.title Presentation Mode
# @vicinae.mode silent
# @vicinae.packageName Arch
# @vicinae.icon /usr/share/icons/WhiteSur/apps/scalable/preferences-desktop-wallpaper.svg
# @vicinae.keywords ["screen share", "apresentacao", "compartilhar tela", "meeting"]

setsid "$HOME/.config/hypr/scripts/PresentationMode.sh" >/dev/null 2>&1 &
