#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
B=mem-v13-2a49f22248
( ./t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-vh1.txt ) &
./longrun.sh vh1 $B "" 5 > vh1.out 2>&1
wait
for L in vc1 vc2 vc3; do
( ./t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-$L.txt ) &
./castlerun.sh $L $B "" > $L.out 2>&1
python3 castlestats.py $L >> $L.out 2>&1
wait
done
echo done > valseq.done
