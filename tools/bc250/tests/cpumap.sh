#!/bin/bash
# cpumap.sh <label>: during the walk, which threads share the GPU front/back cores.
L=$1; cd ~/oot-bc250-tests; out=cpumap-$L.txt; : > $out
until [ -f shot-$L-start.png ]; do sleep 1; done
P=$(pgrep -x eden-cli)
for t in /proc/$P/task/*; do n=$(cat $t/comm); case "$n" in GPU|GPUBack) echo "$n $(basename $t) $(taskset -pc $(basename $t) | cut -d: -f2)" >> $out;; esac; done
for i in $(seq 40); do ps -L -o tid=,psr=,comm= -p $P >> $out.raw; echo "--" >> $out.raw; ps -eLo psr=,pid=,comm=,stat= | awk "\$4 ~ /R/" >> $out.run; echo "--" >> $out.run; sleep 0.5; done
