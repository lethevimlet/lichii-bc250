#!/bin/bash
cd ~/oot-bc250-tests
run() { R=$1 L=$2; echo "== $L $(date +%T)" >> reclaimhelper.log
  systemd-run --user --collect --unit=rh-$L /bin/bash ~/oot-bc250-tests/reclaimhelper.sh >/dev/null
  ./routerun.sh $R $L v17-4fbde27eb7 ""; sleep 10; }
run castle2 castle2-at1; run castle2 castle2-at2; run horse horse-at1
