#!/bin/bash
# threadcpu.sh <label>: per-thread CPU % over 10 s from the middle of the walk.
L=$1; cd ~/oot-bc250-tests
until [ -f shot-$L-start.png ]; do sleep 1; done; sleep 8
P=$(pgrep -x eden-cli); T=$(getconf CLK_TCK)
snap() { for t in /proc/$P/task/*; do echo "$(basename $t) $(cat $t/comm | tr " " _) $(awk "{print \$14+\$15}" $t/stat)"; done; }
snap > /tmp/tc1; sleep 10; snap > /tmp/tc2
join /tmp/tc1 /tmp/tc2 | awk -v T=$T "{d=(\$5-\$3)/T/10*100; if (d>3) printf \"%5.1f%% %s\n\", d, \$2}" | sort -rn > threadcpu-$L.txt
