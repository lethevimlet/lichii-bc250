#!/bin/bash
# isocore.sh: while eden-cli runs, keep GPU (front) on CPU 1, GPUBack on CPU 2, and every other eden thread on CPUs 4-15,
# so the two GPU threads each have a physical core (siblings 0 and 3 stay free). Re-applied every 5 s (new threads).
until P=$(pgrep -x eden-cli); do sleep 1; done; sleep 20
while [ -d /proc/$P ]; do
  for t in /proc/$P/task/*; do
    id=${t##*/}; c=$(cat $t/comm 2>/dev/null)
    case "$c" in
      GPU) m=1 ;; GPUBack) m=2 ;; *) m=4-15 ;;
    esac
    taskset -pc $m $id >/dev/null 2>&1
  done
  sleep 5
done
