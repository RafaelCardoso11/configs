#!/bin/bash
# @vicinae.schemaVersion 1
# @vicinae.title Notification History
# @vicinae.mode silent
# @vicinae.packageName Arch
# @vicinae.icon /usr/share/icons/WhiteSur/apps/scalable/preferences-desktop-notification.svg
# @vicinae.keywords ["notificações", "notifications", "historico"]

setsid "$HOME/.config/hypr/scripts/NotifyHistory.sh" >/dev/null 2>&1 &
