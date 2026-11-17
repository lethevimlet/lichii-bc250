#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
for p in new2:v7-f75bbec369 old2:v7-3010d23c35 new3:v7-f75bbec369 old3:v7-3010d23c35; do
L=${p%%:*}; B=${p#*:}
./castlerun.sh $L $B "" > ${BC250_HOME:-$HOME}/oot-bc250-tests/$L.out 2>&1
python3 castlestats.py $L >> ${BC250_HOME:-$HOME}/oot-bc250-tests/$L.out 2>&1
done
