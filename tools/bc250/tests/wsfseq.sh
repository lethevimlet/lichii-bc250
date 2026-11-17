#!/bin/bash
# wsfseq.sh (root): castle runs at different vm.watermark_scale_factor values, then back to 1000
T=${BC250_HOME:-$HOME}/oot-bc250-tests
for p in w125a:125 w1000a:1000 w300a:300 w125b:125 w1000b:1000 w300b:300; do L=${p%%:*}; V=${p#*:}
  sysctl -qw vm.watermark_scale_factor=$V
  echo "$L wsf=$(cat /proc/sys/vm/watermark_scale_factor)" >> $T/wsfseq.log
  runuser -u "${BC250_USER:-$USER}" -- env XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
    systemd-run --user --wait --collect --quiet --unit=wsf-$L /bin/bash $T/withtest.sh /bin/bash -c \
    "cd $T; ./t1watch.sh $T/t1-$L.txt & ./castlerun.sh $L v12-3794d4f06e \"EDEN_NX2_STUTTER_TRACE=1;EDEN_NX2_STAGING_CAP_MIB=64\" > $L.out 2>&1; python3 castlestats.py $L >> $L.out 2>&1; wait"
done
sysctl -qw vm.watermark_scale_factor=1000
echo "done wsf=$(cat /proc/sys/vm/watermark_scale_factor)" >> $T/wsfseq.log
