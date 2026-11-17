#!/bin/bash
# perfseq.sh (root): castle run, perf the GPUBack thread for 10 s from town2+8 s; perf_event_paranoid restored after
T=${BC250_HOME:-$HOME}/oot-bc250-tests; L=pf13b
OLD=$(cat /proc/sys/kernel/perf_event_paranoid); sysctl -qw kernel.perf_event_paranoid=-1
( until grep -q "^town2 " $T/long-$L.txt 2>/dev/null; do sleep 1; done; sleep 8
  P=$(pgrep -x eden-cli); TID=$(for t in /proc/$P/task/*; do [ "$(cat $t/comm)" = GPUBack ] && echo ${t##*/}; done)
  echo "pid $P back $TID" > $T/perf-$L.log
  runuser -u "${BC250_USER:-$USER}" -- distrobox enter bc250-meshbuild -- perf record -F 2999 -g -t $TID -o /tmp/perf-$L.data -- sleep 10 >> $T/perf-$L.log 2>&1
  echo "perf exit $?" >> $T/perf-$L.log ) &
runuser -u "${BC250_USER:-$USER}" -- env XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
  systemd-run --user --wait --collect --quiet --unit=perf-$L /bin/bash $T/withtest.sh /bin/bash -c \
  "cd $T; ./castlerun.sh $L v13-2a49f22248 '' > $L.out 2>&1; python3 castlestats.py $L >> $L.out 2>&1"
wait
sysctl -qw kernel.perf_event_paranoid=$OLD
echo "done paranoid=$(cat /proc/sys/kernel/perf_event_paranoid)" >> $T/perf-$L.log
