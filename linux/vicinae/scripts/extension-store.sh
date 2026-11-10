#!/bin/bash
# @vicinae.schemaVersion 1
# @vicinae.title Extension Store
# @vicinae.mode silent
# @vicinae.packageName Arch
# @vicinae.icon /usr/share/icons/WhiteSur/apps/scalable/softwarecenter.svg

setsid vicinae vicinae://launch/core/store >/dev/null 2>&1 &
