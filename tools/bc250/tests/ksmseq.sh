#!/bin/bash
# ksmseq.sh (root): castle runs with the emulator opted into KSM; logs merge stats; KSM off afterwards
T=${BC250_HOME:-$HOME}/oot-bc250-tests
K=/sys/kernel/mm/ksm
sed -i 's|eden-bins/mem-v13-[0-9a-f]*/eden-cli|eden-bins/mem-v13-4bb2bfc0d4/eden-cli|' ${BC250_HOME:-$HOME}/Applications/eden-bins/ksm-db04434a51/eden-cli
echo 1 > $K/use_zero_pages; echo 2000 > $K/pages_to_scan; echo 20 > $K/sleep_millisecs; echo 1 > $K/run
for L in ks1 ks2; do
  ( while ! pgrep -x eden-cli >/dev/null; do sleep 1; done
    while P=$(pgrep -x eden-cli); do
      echo "$(date +%T) sharing $(cat $K/pages_sharing) shared $(cat $K/pages_shared) zero $(cat $K/ksm_zero_pages) proc: $(tr '\n' ' ' < /proc/$P/ksm_stat 2>/dev/null) ksmd_cpu $(ps -o %cpu= -C ksmd)" >> $T/ksm-$L.log
      sleep 10; done ) &
  runuser -u "${BC250_USER:-$USER}" -- env XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
    systemd-run --user --wait --collect --quiet --unit=ksm-$L /bin/bash $T/withtest.sh /bin/bash -c \
    "cd $T; ./t1watch.sh $T/t1-$L.txt & ./castlerun.sh $L ksm-db04434a51 '' > $L.out 2>&1; python3 castlestats.py $L >> $L.out 2>&1; wait"
  wait
done
echo 2 > $K/run   # unmerge everything and stop
sleep 5; echo 0 > $K/run
echo "done run=$(cat $K/run)" >> $T/ksmseq.log
