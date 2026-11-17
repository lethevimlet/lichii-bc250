#!/bin/bash
# plazacpu.sh <label>: per-thread CPU % (and major faults) over 10 s windows from the town1 and town2 marks + 8 s
L=$1; cd ~/oot-bc250-tests
for mark in plaza1 town2; do
  until grep -q "^$mark " long-$L.txt 2>/dev/null; do sleep 1; done; sleep 3
  P=$(pgrep -x eden-cli); T=$(getconf CLK_TCK)
  snap() { for t in /proc/$P/task/*; do echo "$(basename $t) $(cat $t/comm | tr " " _) $(awk "{print \$14+\$15, \$12}" $t/stat)"; done; }
  snap > /tmp/pc-a; sleep 10; snap > /tmp/pc-b
  echo "== $L $mark+8s (CPU % over 10 s, major faults)" >> plazacpu-$L.txt
  join <(sort /tmp/pc-a) <(sort /tmp/pc-b) | awk -v T=$T '{c=($6-$3)*100/T/10; f=$7-$4; if(c>3||f>100) printf "%-22s %5.1f %%  majflt %d\n", $2, c, f}' | sort -k2 -rn >> plazacpu-$L.txt
done
