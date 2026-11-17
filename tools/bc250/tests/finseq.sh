#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
for p in f12a:v12-5fcb36b242 f13a:v13-2a49f22248 f12b:v12-5fcb36b242 f13b:v13-2a49f22248 f12c:v12-5fcb36b242 f13c:v13-2a49f22248; do L=${p%%:*}; X=${p#*:}
( ./t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-$L.txt ) &
./castlerun.sh $L $X "" > $L.out 2>&1
python3 castlestats.py $L >> $L.out 2>&1
wait
done
echo done > finseq.done
