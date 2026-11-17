#!/bin/bash
# v19r.sh <bin>: castle2 with the small image pool at 32 and 64 MiB (timed creates + stutter sites). Writes v19r.done.
cd ~/oot-bc250-tests; rm -f v19r.done; B=$1
run() { L=$1 E=$2; systemd-run --user --collect --unit=rh-$L /bin/bash ~/oot-bc250-tests/reclaimhelper.sh >/dev/null
  bash ./withtest.sh ./routerun.sh castle2 $L $B "$E"; sleep 10; }
run castle2-rs32 "EDEN_NX2_TC_CREATE_STATS=1;EDEN_NX2_STUTTER_TRACE=1;EDEN_NX2_IMAGE_RECYCLE_SMALL_MIB=32"
run castle2-rs64 "EDEN_NX2_TC_CREATE_STATS=1;EDEN_NX2_STUTTER_TRACE=1;EDEN_NX2_IMAGE_RECYCLE_SMALL_MIB=64"
date > v19r.done
