#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
B=mem-v13-454c077a34
for p in "h11a|EDEN_NX2_HOT_EPOCH_SHIFT=11" "h7a|" "h11b|EDEN_NX2_HOT_EPOCH_SHIFT=11" "h7b|" "h11c|EDEN_NX2_HOT_EPOCH_SHIFT=11" "h7c|"; do
L=${p%%|*}; E=${p#*|}
( ./t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-$L.txt ) &
./castlerun.sh $L $B "EDEN_NX2_PROTECT_STATS=1;$E" > $L.out 2>&1
python3 castlestats.py $L >> $L.out 2>&1
wait
done
echo done > hotseq.done
