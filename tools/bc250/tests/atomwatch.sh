#!/bin/bash
# atomwatch.sh <out>: every 2 s, the gamescope root window properties (Steam settings show up there).
while true; do echo "== $(date +%T)"; DISPLAY=:0 xprop -root | grep -E "^GAMESCOPE"; sleep 2; done > "$1"
