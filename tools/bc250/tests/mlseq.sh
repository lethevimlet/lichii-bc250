#!/bin/bash
# mlseq.sh (root): castle runs with memory.low protection on the emulator; reset to 0 after each run
T=${BC250_HOME:-$HOME}/oot-bc250-tests
reset() { find /sys/fs/cgroup/user.slice -maxdepth 7 -name memory.low 2>/dev/null | while read f; do [ "$(cat $f)" != 0 ] && echo 0 > $f; done; }
reset
for p in m6a:6G m4a:4G m0a:0 m6b:6G m4b:4G m0b:0; do L=${p%%:*}; V=${p#*:}
  [ "$V" != 0 ] && ( bash $T/memprot.sh $V; cp /tmp/memprot.log $T/memprot-$L.log ) &
  runuser -u "${BC250_USER:-$USER}" -- env XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
    systemd-run --user --wait --collect --quiet --unit=ml-$L /bin/bash $T/withtest.sh /bin/bash -c \
    "cd $T; ./t1watch.sh $T/t1-$L.txt & ./castlerun.sh $L v12-3794d4f06e \"EDEN_NX2_STUTTER_TRACE=1;EDEN_NX2_STAGING_CAP_MIB=64\" > $L.out 2>&1; python3 castlestats.py $L >> $L.out 2>&1; wait"
  wait; reset
  echo "$L low=$V done, nonzero lows left: $(find /sys/fs/cgroup/user.slice -maxdepth 7 -name memory.low -exec grep -Hv '^0$' {} \; | wc -l)" >> $T/mlseq.log
done
echo done >> $T/mlseq.log
