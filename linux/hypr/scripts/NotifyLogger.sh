#!/bin/bash
# Logs every desktop notification to ~/.cache/notify-history (one line each),
# read back by NotifyHistory.sh. Started once from Startup_Apps.conf.

log="$HOME/.cache/notify-history"

# Notify(app_name, replaces_id, app_icon, summary, body, ...): the first four
# string args after the method call are app, icon, summary and body.
# ponytail: multi-line bodies keep only their first line; good enough for a history list
dbus-monitor --session "interface='org.freedesktop.Notifications',member='Notify'" |
  awk -v out="$log" '
    /member=Notify/ { n = 0; next }
    n < 4 && /^ +string "/ {
      s = $0; sub(/^ +string "/, "", s); sub(/"$/, "", s)
      v[n++] = s
      if (n == 4) {
        cmd = "date +%H:%M"; cmd | getline t; close(cmd)
        printf "%s  %s — %s %s\n", t, v[0], v[2], v[3] >> out
        fflush(out)
      }
    }'
