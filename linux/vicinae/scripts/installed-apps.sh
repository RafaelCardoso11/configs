#!/bin/bash
# @vicinae.schemaVersion 1
# @vicinae.title Installed Apps
# @vicinae.mode silent
# @vicinae.packageName Arch
# @vicinae.icon /usr/share/icons/WhiteSur/apps/scalable/view-app-grid.svg
# @vicinae.keywords ["apps", "aplicativos", "browse", "installed", "instalados"]

# vicinae's own "Browse Apps" works but root search never suggests it, so this opens it by deeplink
setsid vicinae vicinae://launch/system/browse-apps >/dev/null 2>&1 &
