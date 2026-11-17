#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
for p in w14a:v14-aaba473404 w13a:v13-2a49f22248 w14b:v14-aaba473404 w13b:v13-2a49f22248 w14c:v14-aaba473404; do L=${p%%:*}; X=${p#*:}
( ./t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-$L.txt ) &
./castlerun.sh $L $X "" > $L.out 2>&1
python3 castlestats.py $L >> $L.out 2>&1
wait
done
echo done > v14seq.done
