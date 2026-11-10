#!/bin/bash
# @vicinae.schemaVersion 1
# @vicinae.title Sleep
# @vicinae.mode silent
# @vicinae.packageName Arch
# @vicinae.icon /usr/share/icons/WhiteSur/apps/scalable/suspend.svg

setsid systemctl suspend >/dev/null 2>&1 &
