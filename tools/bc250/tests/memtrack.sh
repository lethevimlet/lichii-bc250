#!/bin/bash
# memtrack.sh <label>: every 30 s while eden-cli runs, save a smaps summary (smapsum.py) stamped with seconds since the
# game appeared. Runs until /tmp/memtrack-stop-<label> exists (memrun.sh creates it when the route is over).
L=$1; cd ${BC250_HOME:-$HOME}/oot-bc250-tests; out=memtrack-$L.txt; : > $out; rm -f /tmp/memtrack-stop-$L
t0=
while [ ! -e /tmp/memtrack-stop-$L ]; do
  P=$(pgrep -x eden-cli | tail -1)
  if [ -n "$P" ]; then
    [ -z "$t0" ] && t0=$(date +%s)
    cp /proc/$P/smaps /tmp/smaps-$L 2>/dev/null && { echo "== t=$(( $(date +%s) - t0 )) pid=$P"; grep -E "RssAnon|VmSwap" /proc/$P/status | tr -s " " | tr "\n" " "; echo; python3 -I smapsum.py /tmp/smaps-$L; } >> $out 2>&1
    sleep 30
  else
    sleep 3
  fi
done
