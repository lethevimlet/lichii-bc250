#!/bin/bash
L=$1; cd ~/oot-bc250-tests
until [ -f shot-$L-start.png ]; do sleep 1; done; sleep 5
P=$(pgrep -x eden-cli)
distrobox enter bc250-meshbuild -- perf record -q -e cycles -F 1500 -p $P -o ${BC250_HOME:-$HOME}/oot-bc250-tests/perf-$L-all.data -- sleep 15 >/dev/null 2>&1
