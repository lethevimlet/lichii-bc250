#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
for p in np1:v13-2a49f22248 np2:v13-2a49f22248 np3:v13-2a49f22248; do L=${p%%:*}; X=${p#*:}
( ./t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-$L.txt ) &
./castlerun.sh $L $X "BC250_NO_PERFMODE=1" > $L.out 2>&1
python3 castlestats.py $L >> $L.out 2>&1
wait
done
echo done > npseq.done
