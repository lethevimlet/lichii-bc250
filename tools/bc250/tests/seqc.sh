#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
for p in c64a:64 c16a:16 c64b:64 c16b:16; do L=${p%%:*}; X=v12-3794d4f06e; C=${p#*:}
( ./t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-$L.txt ) &
./castlerun.sh $L $X "EDEN_NX2_STUTTER_TRACE=1;EDEN_NX2_STAGING_CAP_MIB=$C" > ${BC250_HOME:-$HOME}/oot-bc250-tests/$L.out 2>&1
python3 castlestats.py $L >> ${BC250_HOME:-$HOME}/oot-bc250-tests/$L.out 2>&1
wait
done
