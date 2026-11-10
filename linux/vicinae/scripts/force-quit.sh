#!/bin/bash
# @vicinae.schemaVersion 1
# @vicinae.title Force Quit…
# @vicinae.mode silent
# @vicinae.packageName Arch
# @vicinae.icon /usr/share/icons/WhiteSur/apps/scalable/utilities-system-monitor.svg

setsid vicinae 'vicinae://launch/@leonkohli/store.vicinae.process-manager/processes' >/dev/null 2>&1 &
