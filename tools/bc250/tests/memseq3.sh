#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
B=mem-v13-4bb2bfc0d4
for p in "d2a|" "d2b|" "d2c|" "d2d|"; do
L=${p%%|*}; E=${p#*|}
( ./t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-$L.txt ) &
./castlerun.sh $L $B "EDEN_NX2_VMA_PEAK_DUMP=/tmp/vp-$L.json;$E" > $L.out 2>&1
python3 castlestats.py $L >> $L.out 2>&1
cp /tmp/vp-$L.json* . 2>/dev/null
wait
done
echo done > memseq3.done
