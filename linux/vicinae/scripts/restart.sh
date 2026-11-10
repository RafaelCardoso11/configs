#!/bin/bash
# @vicinae.schemaVersion 1
# @vicinae.title Restart…
# @vicinae.mode silent
# @vicinae.packageName Arch
# @vicinae.icon /usr/share/icons/WhiteSur/apps/scalable/reboot.svg

setsid vicinae vicinae://launch/power/reboot >/dev/null 2>&1 &
