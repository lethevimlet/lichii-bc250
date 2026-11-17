#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
for p in cA3:v11-0f67d668d3 cA4:v11-0f67d668d3; do L=${p%%:*}; X=${p#*:}
( ./t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-$L.txt ) &
./castlerun.sh $L $X "EDEN_NX2_STUTTER_TRACE=1" > ${BC250_HOME:-$HOME}/oot-bc250-tests/$L.out 2>&1
python3 castlestats.py $L >> ${BC250_HOME:-$HOME}/oot-bc250-tests/$L.out 2>&1
wait
done
