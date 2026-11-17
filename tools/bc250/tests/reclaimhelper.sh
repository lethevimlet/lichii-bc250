#!/bin/bash
# reclaimhelper.sh: the installer wrapper reclaim helper, for the test harness (waits for the game).
request="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/lichii-bc250-reclaim"; rm -f "$request"
until pgrep -x eden-cli >/dev/null; do sleep 1; done
while pgrep -x eden-cli >/dev/null; do
  if [ -s "$request" ]; then
    amount=$(head -c 16 "$request"); rm -f "$request"
    pid=$(pgrep -x eden-cli | head -n 1); cg=$(cut -d: -f3 "/proc/$pid/cgroup" 2>/dev/null); cg=${cg%/container}
    t0=$(date +%s.%N)
    [[ "$amount" =~ ^[0-9]+M$ ]] && [ -n "$cg" ] && echo "$amount" > "/sys/fs/cgroup$cg/memory.reclaim"
    echo "$(date +%T) reclaimed $amount in $(echo "$(date +%s.%N) - $t0" | bc) s" >> ~/oot-bc250-tests/reclaimhelper.log
  fi
  sleep 0.25
done
