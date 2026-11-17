#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
for p in iso1:1 nor1:0 iso2:1 nor2:0 iso3:1 nor3:0; do L=${p%%:*}; V=${p#*:}
  [ $V = 1 ] && ( ./isocore.sh ) &
  ( ./t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-$L.txt ) &
  ./castlerun.sh $L mem-v13-4bb2bfc0d4 "" > $L.out 2>&1
  python3 castlestats.py $L >> $L.out 2>&1
  wait
done
echo done > isoseq.done
