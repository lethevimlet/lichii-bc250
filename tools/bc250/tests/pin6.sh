#!/bin/bash
# pin6.sh: once eden-cli runs, pin CPUCore_N to its own physical core (first hyperthread of cores
# 0,3,4,5,6,7 = CPUs 0,6,8,10,12,14); the GPU threads keep cores 1 and 2 (CPUs 2-5).
CPUS=(${PIN6_CPUS:-0 6 8 10 12 14})
for i in $(seq 120); do pgrep -x eden-cli >/dev/null && break; sleep 2; done
P=$(pgrep -x eden-cli); sleep 25
for t in /proc/$P/task/*; do
  n=$(cat $t/comm)
  case $n in CPUCore_[0-5]) taskset -pc ${CPUS[${n#CPUCore_}]} $(basename $t) >/dev/null ;; esac
done
for t in /proc/$P/task/*; do n=$(cat $t/comm); case $n in CPUCore_*) echo "$n $(taskset -pc $(basename $t) | cut -d: -f2)";; esac; done
