#!/bin/bash
# pfseq.sh (root): castle runs with/without pulling swapped game memory back 10 s after each town arrival
T=${BC250_HOME:-$HOME}/oot-bc250-tests
sed 's/line.startswith("MemAvailable:")/line.startswith("MemFree:")/' $T/swapback.py > $T/swapback-free.py
for L in pfa nfa pfb nfb; do
  rm -f $T/long-$L.txt
  if [ "${L:0:2}" = pf ]; then
    ( for mark in town1 town2; do
        until grep -q "^$mark " $T/long-$L.txt 2>/dev/null; do sleep 1; done
        sleep 10; P=$(pgrep -x eden-cli)
        echo "$L $mark start $(date +%s) pid $P" >> $T/pfseq.log
        timeout 45 python3 $T/swapback-free.py $P 1800 300 >> $T/pfseq.log 2>&1
        echo "$L $mark end $(date +%s)" >> $T/pfseq.log
      done ) &
  fi
  runuser -u "${BC250_USER:-$USER}" -- env XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
    systemd-run --user --wait --collect --quiet --unit=pf-$L /bin/bash $T/withtest.sh /bin/bash -c \
    "cd $T; ./t1watch.sh $T/t1-$L.txt & ./castlerun.sh $L v12-3794d4f06e \"EDEN_NX2_STUTTER_TRACE=1;EDEN_NX2_STAGING_CAP_MIB=64\" > $L.out 2>&1; python3 castlestats.py $L >> $L.out 2>&1; wait"
  wait
done
echo done >> $T/pfseq.log
