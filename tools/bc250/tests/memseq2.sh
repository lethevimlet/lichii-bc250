#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
B=mem-v13-e38acc162b
for p in "d1a|" "d1b|" "d1c|" "d1d|"; do
L=${p%%|*}; E=${p#*|}
( ./t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-$L.txt ) &
./castlerun.sh $L $B "EDEN_NX2_VMA_PEAK_DUMP=/tmp/vp-$L.json;$E" > $L.out 2>&1
python3 castlestats.py $L >> $L.out 2>&1
cp /tmp/vp-$L.json* . 2>/dev/null
wait
done
echo done > memseq2.done
