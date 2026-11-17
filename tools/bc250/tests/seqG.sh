#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
for p in ctrv7b:ctr-v7; do L=${p%%:*}; B=${p#*:}
./castlerun.sh $L $B "" > ${BC250_HOME:-$HOME}/oot-bc250-tests/$L.out 2>&1
python3 castlestats.py $L >> ${BC250_HOME:-$HOME}/oot-bc250-tests/$L.out 2>&1
done
