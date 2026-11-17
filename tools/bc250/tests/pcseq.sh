#!/bin/bash
# wsfseq.sh (root): castle runs at different vm.watermark_scale_factor values, then back to 1000
T=${BC250_HOME:-$HOME}/oot-bc250-tests
for p in pc3a:3 pc0a:0 pc2a:2 pc3b:3 pc0b:0 pc2b:2; do L=${p%%:*}; V=${p#*:}
  sysctl -qw vm.page-cluster=$V
  echo "$L pc=$(cat /proc/sys/vm/page-cluster)" >> $T/pcseq.log
  runuser -u "${BC250_USER:-$USER}" -- env XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
    systemd-run --user --wait --collect --quiet --unit=pcl-$L /bin/bash $T/withtest.sh /bin/bash -c \
    "cd $T; ./t1watch.sh $T/t1-$L.txt & ./castlerun.sh $L v12-3794d4f06e \"EDEN_NX2_STUTTER_TRACE=1;EDEN_NX2_STAGING_CAP_MIB=64\" > $L.out 2>&1; python3 castlestats.py $L >> $L.out 2>&1; wait"
done
sysctl -qw vm.page-cluster=0
echo "done pc=$(cat /proc/sys/vm/page-cluster)" >> $T/pcseq.log
