#!/bin/bash
# @vicinae.schemaVersion 1
# @vicinae.title Log Out…
# @vicinae.mode silent
# @vicinae.packageName Arch
# @vicinae.icon /usr/share/icons/WhiteSur/apps/scalable/log-out.svg

setsid vicinae vicinae://launch/power/logout >/dev/null 2>&1 &
