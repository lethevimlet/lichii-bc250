#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
B=mem-v13-7013485e13
for p in u1536a:1536:2048 u2048a:2048:2560 u2560a:2560:3072 u1536b:1536:2048 u2048b:2048:2560 u2560b:2560:3072; do
IFS=: read L E C <<<"$p"
( ./t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-$L.txt ) &
./castlerun.sh $L $B "EDEN_NX2_TC_LOG=300;EDEN_NX2_TC_EXPECTED_MIB=$E;EDEN_NX2_TC_CRITICAL_MIB=$C" > $L.out 2>&1
python3 castlestats.py $L >> $L.out 2>&1
wait
done
echo done > tc2seq.done
