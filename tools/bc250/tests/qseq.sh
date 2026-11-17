#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
B=mem-v13-7013485e13
for p in q1a:1 q2a:2 q1b:1 q2b:2 q1c:1 q2c:2; do L=${p%%:*}; Q=${p#*:}
( ./t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-$L.txt ) &
INI="pin_gpu_threads=true;frame_gen_target_rate=0;frame_gen_queue_target=$Q" ./castlerun.sh $L $B "" > $L.out 2>&1
python3 castlestats.py $L >> $L.out 2>&1
wait
done
echo done > qseq.done
