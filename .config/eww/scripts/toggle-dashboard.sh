#!/usr/bin/env bash
# Toggle eww dashboard on all monitors

visible=$(eww get dashboard-visible 2>/dev/null)

if [[ "$visible" == "true" ]]; then
  eww update dashboard-visible=false
  eww close dashboard-0 2>/dev/null
  eww close dashboard-1 2>/dev/null
else
  eww update dashboard-visible=true
  eww open dashboard-0 2>/dev/null
  eww open dashboard-1 2>/dev/null
fi
