#!/bin/bash
# wbseq.sh (root): castle runs with zram writeback of incompressible pages every 2 s
T=${BC250_HOME:-$HOME}/oot-bc250-tests
bash $T/zwb.sh daemon 2 & D=$!
for L in wb1 wb2 wb3 wb4; do
  ( while ! pgrep -x eden-cli >/dev/null; do sleep 1; done
    while pgrep -x eden-cli >/dev/null; do echo "$(date +%T) $(cat /sys/block/zram0/mm_stat) | bd $(cat /sys/block/zram0/bd_stat)" >> $T/zwb-$L.log; sleep 5; done ) &
  runuser -u "${BC250_USER:-$USER}" -- env XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
    systemd-run --user --wait --collect --quiet --unit=wb-$L /bin/bash $T/withtest.sh /bin/bash -c \
    "cd $T; ./t1watch.sh $T/t1-$L.txt & ./castlerun.sh $L mem-v13-4bb2bfc0d4 '' > $L.out 2>&1; python3 castlestats.py $L >> $L.out 2>&1; wait"
  wait $(jobs -p | grep -v "^$D$") 2>/dev/null
done
kill $D
echo done > $T/wbseq.done
