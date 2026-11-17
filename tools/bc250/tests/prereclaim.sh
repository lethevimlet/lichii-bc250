#!/bin/bash
# prereclaim.sh <label> <delay after start> <amount>: when the route starts (Link walks to the gate), wait <delay>
# s, then ask the kernel to reclaim <amount> from the emulator container scope (memory.reclaim); logs timing.
L=$1 D=$2 A=$3; cd ~/oot-bc250-tests
until grep -q "^start " long-$L.txt 2>/dev/null; do sleep 0.5; done
sleep $D
P=$(pgrep -x eden-cli); CG=$(cut -d: -f3 /proc/$P/cgroup); CG=${CG%/container}
F=/sys/fs/cgroup$CG/memory.reclaim
avail() { awk "/MemAvailable/{print int(\$2/1024)}" /proc/meminfo; }
echo "$(date +%T.%N | cut -c1-12) reclaim $A from $CG, available $(avail) MiB" >> prereclaim-$L.txt
t0=$(date +%s.%N); echo $A > $F 2>>prereclaim-$L.txt; t1=$(date +%s.%N)
echo "$(date +%T) done in $(echo "$t1 - $t0" | bc) s, available $(avail) MiB" >> prereclaim-$L.txt
