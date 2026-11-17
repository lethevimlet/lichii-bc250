#!/bin/bash
# acctseq.sh (root): one castle run on the v13 build, full memory accounting 20 s into plaza1
T=${BC250_HOME:-$HOME}/oot-bc250-tests
L=ma13
( bash $T/memacct.sh $L plaza1 20 ) &
runuser -u "${BC250_USER:-$USER}" -- env XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
  systemd-run --user --wait --collect --quiet --unit=acct-$L /bin/bash $T/withtest.sh /bin/bash -c \
  "cd $T; ./t1watch.sh $T/t1-$L.txt & ./castlerun.sh $L mem-v13-4bb2bfc0d4 '' > $L.out 2>&1; python3 castlestats.py $L >> $L.out 2>&1; wait"
wait
echo done > $T/acctseq.done
