#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
for p in k11a:v11-0f67d668d3 k12a:v12-5fcb36b242 k11b:v11-0f67d668d3 k12b:v12-5fcb36b242 k11c:v11-0f67d668d3 k12c:v12-5fcb36b242 k11d:v11-0f67d668d3 k12d:v12-5fcb36b242; do L=${p%%:*}; X=${p#*:}
( ./t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-$L.txt ) &
./castlerun.sh $L $X "" > $L.out 2>&1
python3 castlestats.py $L >> $L.out 2>&1
wait
done
