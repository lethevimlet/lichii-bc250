#!/bin/bash
# perfbuild.sh <label>: 25 s of perf on GPUBack starting right after the save loads (cold-cache pipeline builds).
L=$1; cd ~/oot-bc250-tests
until [ -f shot-$L-start.png ]; do sleep 1; done
P=$(pgrep -x eden-cli); echo "pid $P" > perfbuild-$L.txt; T=$(for t in /proc/$P/task/*; do [ "$(cat $t/comm)" = GPUBack ] && basename $t; done | head -1)
echo "tid $T" >> perfbuild-$L.txt; distrobox enter bc250-meshbuild -- sudo -n perf record -q -e cycles:u -F 1500 --call-graph=fp -t $T -o ${BC250_HOME:-$HOME}/oot-bc250-tests/perf-$L-back.data -- sleep 25 >> perfbuild-$L.txt 2>&1
