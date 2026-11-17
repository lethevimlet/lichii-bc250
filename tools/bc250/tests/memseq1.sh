#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
B=mem-v13-db04434a51
for p in "r0a|" "r64a|EDEN_NX2_ASTC_PENDING_MIB=64;EDEN_NX2_ASTC_FREE_MIB=64" "r32a|EDEN_NX2_ASTC_PENDING_MIB=32;EDEN_NX2_ASTC_FREE_MIB=0" "r0b|" "r64b|EDEN_NX2_ASTC_PENDING_MIB=64;EDEN_NX2_ASTC_FREE_MIB=64" "r32b|EDEN_NX2_ASTC_PENDING_MIB=32;EDEN_NX2_ASTC_FREE_MIB=0"; do
L=${p%%|*}; E=${p#*|}
( ./t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-$L.txt ) &
./castlerun.sh $L $B "EDEN_NX2_VMA_PEAK_DUMP=/tmp/vp-$L.json;$E" > $L.out 2>&1
python3 castlestats.py $L >> $L.out 2>&1
cp /tmp/vp-$L.json* . 2>/dev/null
wait
done
echo done > memseq1.done
