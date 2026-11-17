#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
B=mem-v13-a705fdd94e
for p in "rd3a|EDEN_NX2_RT_TRACK_DELAY=3" "rd0a|" "rd3b|EDEN_NX2_RT_TRACK_DELAY=3" "rd0b|" "rd3c|EDEN_NX2_RT_TRACK_DELAY=3" "rd0c|"; do
L=${p%%|*}; E=${p#*|}
( ./t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-$L.txt ) &
./castlerun.sh $L $B "EDEN_NX2_PROTECT_STATS=1;$E" > $L.out 2>&1
python3 castlestats.py $L >> $L.out 2>&1
wait
done
echo done > rtdseq.done
