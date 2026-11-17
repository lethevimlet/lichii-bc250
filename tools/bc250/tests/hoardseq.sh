#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
for p in h0a:0 hda:d h0b:0 hdb:d; do L=${p%%:*}; V=${p#*:}
E="EDEN_NX2_STAGING_CAP_MIB=64"; [ $V = 0 ] && E="$E;EDEN_NX2_IMAGE_RECYCLE_MIB=0;EDEN_NX2_MEM_RESERVE_MIB=0"
( ./t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-$L.txt ) &
./castlerun.sh $L v12-3794d4f06e "$E" > $L.out 2>&1
python3 castlestats.py $L >> $L.out 2>&1
wait
done
