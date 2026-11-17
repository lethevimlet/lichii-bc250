#!/bin/bash
# vmsnap.sh <label>: /proc/vmstat counters and the emulator uptime (= log time) at game start,
# walk start and walk end (from the measure script screenshots).
cd ~/oot-bc250-tests; L=$1; out=vm-$L.txt; rm -f $out
for i in $(seq 60); do pgrep -x eden-cli >/dev/null && break; sleep 3; done
snap() { P=$(pgrep -x eden-cli); echo "== $1 $(date +%T) uptime $(ps -o etimes= -p $P | tr -d ' ')" >> $out; grep -E "^(compact_stall|allocstall_normal|allocstall_movable|pswpin|pswpout|pgmajfault) " /proc/vmstat >> $out; }
snap start
until [ -f shot-$L-start.png ]; do pgrep -x eden-cli >/dev/null || exit; sleep 1; done; snap walk
until [ -f shot-$L-end.png ]; do pgrep -x eden-cli >/dev/null || exit; sleep 1; done; snap end
until [ -f shot-$L-x.png ]; do pgrep -x eden-cli >/dev/null || exit; sleep 1; done; snap extra
