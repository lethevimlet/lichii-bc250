#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
for p in nat26a4:rel-v7; do L=${p%%:*}; B=${p#*:}
rm -f long-$L.txt; ( ./snapat.sh $L plaza1 20 ) &
./castlerun.sh $L $B "GLIBC_TUNABLES=glibc.malloc.arena_max=4" > ${BC250_HOME:-$HOME}/oot-bc250-tests/$L.out 2>&1
python3 castlestats.py $L >> ${BC250_HOME:-$HOME}/oot-bc250-tests/$L.out 2>&1
done
