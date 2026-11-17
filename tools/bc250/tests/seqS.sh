#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
for p in hA1:ctr-v7 hB1:v7-f75bbec369 hA2:ctr-v7 hB2:v7-f75bbec369; do L=${p%%:*}; B=${p#*:}
( ./t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-$L.txt ) &
./longrun.sh $L $B "" 6 > ${BC250_HOME:-$HOME}/oot-bc250-tests/$L.out 2>&1
wait
done
