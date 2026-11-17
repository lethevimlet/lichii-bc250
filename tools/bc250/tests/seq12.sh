#!/bin/bash
# seq12.sh: v11 vs v12 alternating, Hyrule long loop (3) + castle route
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
A=v11-0f67d668d3; B=v12-3f7988e465
for p in hA1:$A hB1:$B hA2:$A hB2:$B; do L=${p%%:*}; X=${p#*:}
( ./t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-$L.txt ) &
./longrun.sh $L $X "" 3 > ${BC250_HOME:-$HOME}/oot-bc250-tests/$L.out 2>&1
wait
done
for p in cA1:$A cB1:$B cA2:$A cB2:$B; do L=${p%%:*}; X=${p#*:}
( ./t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-$L.txt ) &
./castlerun.sh $L $X "" > ${BC250_HOME:-$HOME}/oot-bc250-tests/$L.out 2>&1
python3 castlestats.py $L >> ${BC250_HOME:-$HOME}/oot-bc250-tests/$L.out 2>&1
wait
done
echo SEQ12-DONE > ${BC250_HOME:-$HOME}/oot-bc250-tests/seq12.done
