#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
for p in cP7:ctr-v7 cP8:v8-b4930ba81d; do L=${p%%:*}; B=${p#*:}
./castlerun.sh $L $B "EDEN_NX2_VMA_PEAK_DUMP=/tmp/vp-$L.json" > ${BC250_HOME:-$HOME}/oot-bc250-tests/$L.out 2>&1
python3 castlestats.py $L >> ${BC250_HOME:-$HOME}/oot-bc250-tests/$L.out 2>&1
cp /tmp/vp-$L.json* ${BC250_HOME:-$HOME}/oot-bc250-tests/ 2>/dev/null
done
