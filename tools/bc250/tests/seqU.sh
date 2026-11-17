#!/bin/bash
# v8 (Lichii nx2 87d84d513c merge) vs v7 release, castle x3 + Hyrule x2 each, alternating.
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
B8=v8-b4930ba81d
for p in cA1:ctr-v7 cB1:$B8 cA2:ctr-v7 cB2:$B8 cA3:ctr-v7 cB3:$B8; do L=${p%%:*}; B=${p#*:}
./castlerun.sh $L $B "" > ${BC250_HOME:-$HOME}/oot-bc250-tests/$L.out 2>&1
python3 castlestats.py $L >> ${BC250_HOME:-$HOME}/oot-bc250-tests/$L.out 2>&1
done
for p in hA3:ctr-v7 hB3:$B8 hA4:ctr-v7 hB4:$B8; do L=${p%%:*}; B=${p#*:}
( ./t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-$L.txt ) &
./longrun.sh $L $B "" 6 > ${BC250_HOME:-$HOME}/oot-bc250-tests/$L.out 2>&1
wait
done
echo SEQU DONE
