#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
for p in cs1:v12-3794d4f06e ct2:v12-3f7988e465 cs2:v12-3794d4f06e; do L=${p%%:*}; X=${p#*:}
( ./t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-$L.txt ) &
./castlerun.sh $L $X "EDEN_NX2_STUTTER_TRACE=1" > ${BC250_HOME:-$HOME}/oot-bc250-tests/$L.out 2>&1
python3 castlestats.py $L >> ${BC250_HOME:-$HOME}/oot-bc250-tests/$L.out 2>&1
wait
done
