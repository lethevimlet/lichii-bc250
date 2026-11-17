#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
B=v7.2-38f0dff0c1
for p in yA1:ctr-v7 yB1:$B yA2:ctr-v7 yB2:$B yA3:ctr-v7 yB3:$B; do L=${p%%:*}; X=${p#*:}
( ./t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-$L.txt ) &
./longrun.sh $L $X "" 3 > ${BC250_HOME:-$HOME}/oot-bc250-tests/$L.out 2>&1
wait
done
for p in zA1:ctr-v7 zB1:$B zA2:ctr-v7 zB2:$B; do L=${p%%:*}; X=${p#*:}
./castlerun.sh $L $X "" > ${BC250_HOME:-$HOME}/oot-bc250-tests/$L.out 2>&1
python3 castlestats.py $L >> ${BC250_HOME:-$HOME}/oot-bc250-tests/$L.out 2>&1
done
