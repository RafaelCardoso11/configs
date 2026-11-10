#!/bin/bash
# @vicinae.schemaVersion 1
# @vicinae.title Lock Screen
# @vicinae.mode silent
# @vicinae.packageName Arch
# @vicinae.icon /usr/share/icons/WhiteSur/apps/scalable/preferences-desktop-screensaver.svg

setsid loginctl lock-session >/dev/null 2>&1 &
