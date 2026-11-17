#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
B=mem-v13-2a49f22248
for p in "ob1|EDEN_NX2_TC_EXPECTED_MIB=2048;EDEN_NX2_TC_CRITICAL_MIB=2560" "oi4|" "ob2|EDEN_NX2_TC_EXPECTED_MIB=2048;EDEN_NX2_TC_CRITICAL_MIB=2560" "oi5|" "ob3|EDEN_NX2_TC_EXPECTED_MIB=2048;EDEN_NX2_TC_CRITICAL_MIB=2560" "oi6|"; do
L=${p%%|*}; E=${p#*|}
( ./t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-$L.txt ) &
./castlerun.sh $L $B "EDEN_NX2_TC_LOG=300;$E" > $L.out 2>&1
python3 castlestats.py $L >> $L.out 2>&1
wait
done
echo done > tc4seq.done
