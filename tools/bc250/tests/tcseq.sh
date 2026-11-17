#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
for p in t1536a:1536:2048 t1024a:1024:1536 t768a:768:1024 t1536b:1536:2048 t1024b:1024:1536 t768b:768:1024; do
IFS=: read L E C <<<"$p"
( ./t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-$L.txt ) &
./castlerun.sh $L v12-3794d4f06e "EDEN_NX2_STUTTER_TRACE=1;EDEN_NX2_STAGING_CAP_MIB=64;EDEN_NX2_TC_EXPECTED_MIB=$E;EDEN_NX2_TC_CRITICAL_MIB=$C" > $L.out 2>&1
python3 castlestats.py $L >> $L.out 2>&1
wait
done
