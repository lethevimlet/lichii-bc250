#!/bin/bash
# memprot.sh <low>  (root): wait for eden-cli, then set memory.low=<low> on its cgroup and every
# ancestor up to user.slice, so reclaim takes Steam/gamescope/page cache before the emulator.
# Runtime only (the cgroup goes away with the game); logs to /tmp/memprot.log.
LOW=${1:-10G}
for i in $(seq 120); do P=$(pgrep -x eden-cli) && break; sleep 2; done
[ -n "$P" ] || { echo "no eden-cli" >> /tmp/memprot.log; exit 1; }
CG=$(awk -F: "\$1==0{print \$3}" /proc/$P/cgroup)
d=/sys/fs/cgroup$CG
echo "$(date +%T) pid $P cgroup $CG" > /tmp/memprot.log
while [ "$d" != /sys/fs/cgroup ]; do
  [ -w "$d/memory.low" ] && echo "$LOW" > "$d/memory.low" && echo "  $d low=$(cat $d/memory.low)" >> /tmp/memprot.log
  d=$(dirname "$d")
done
# keep reporting how often protection was breached
CGD=/sys/fs/cgroup$CG
while [ -d /proc/$P ]; do sleep 30; echo "$(date +%T) $(grep -E "^(low|high|max)" $CGD/memory.events | tr "\n" " ") cur=$(( $(cat $CGD/memory.current) >> 20 ))MB" >> /tmp/memprot.log; done
