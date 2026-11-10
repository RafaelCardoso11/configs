#!/bin/bash
# @vicinae.schemaVersion 1
# @vicinae.title Shut Down…
# @vicinae.mode silent
# @vicinae.packageName Arch
# @vicinae.icon /usr/share/icons/WhiteSur/apps/scalable/shutdown.svg

setsid vicinae vicinae://launch/power/power-off >/dev/null 2>&1 &
