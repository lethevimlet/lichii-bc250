#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
B=mem-v13-4bb2bfc0d4
for p in "rtb1|" "rtt1|EDEN_NX2_READ_TRAPS=0" "rtr1|EDEN_NX2_IMAGE_RECYCLE_MIB=256" "rtx1|EDEN_NX2_READ_TRAPS=0;EDEN_NX2_IMAGE_RECYCLE_MIB=256" "rtb2|" "rtt2|EDEN_NX2_READ_TRAPS=0" "rtr2|EDEN_NX2_IMAGE_RECYCLE_MIB=256" "rtx2|EDEN_NX2_READ_TRAPS=0;EDEN_NX2_IMAGE_RECYCLE_MIB=256"; do
L=${p%%|*}; E=${p#*|}
( ./t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-$L.txt ) &
./castlerun.sh $L $B "EDEN_NX2_GPU_PROFILE=1;$E" > $L.out 2>&1
python3 castlestats.py $L >> $L.out 2>&1
wait
done
echo done > rtseq.done
