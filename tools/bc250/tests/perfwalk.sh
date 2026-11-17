#!/bin/bash
# perfwalk.sh <label>: during the measured walk, perf-record the GPU front/back threads (user space).
L=$1; cd ~/oot-bc250-tests
until [ -f shot-$L-start.png ]; do sleep 1; done
P=$(pgrep -x eden-cli); ls /proc/$P/task | while read t; do echo "$t $(cat /proc/$P/task/$t/comm)"; done > threads-$L.txt
for name in GPUBack GPU; do
  T=$(awk -v n="$name" "\$2==n{print \$1; exit}" threads-$L.txt)
  [ -n "$T" ] && distrobox enter bc250-meshbuild -- perf record -q -e cycles:u -F 2000 -t $T -o ${BC250_HOME:-$HOME}/oot-bc250-tests/perf-$L-$name.data -- sleep 20 >/dev/null 2>&1 &
done
wait
