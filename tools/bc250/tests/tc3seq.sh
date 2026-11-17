#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
B=mem-v13-2a49f22248
for p in "oi1|" "oo1|EDEN_NX2_TC_OVERRIDE_IMAGES=0" "oi2|" "oo2|EDEN_NX2_TC_OVERRIDE_IMAGES=0" "oi3|" "oo3|EDEN_NX2_TC_OVERRIDE_IMAGES=0"; do
L=${p%%|*}; E=${p#*|}
( ./t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-$L.txt ) &
./castlerun.sh $L $B "EDEN_NX2_TC_LOG=300;$E" > $L.out 2>&1
python3 castlestats.py $L >> $L.out 2>&1
wait
done
echo done > tc3seq.done
