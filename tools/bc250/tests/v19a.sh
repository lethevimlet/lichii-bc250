#!/bin/bash
# v19a.sh: fast-draw stride check (verify run) + 2 castle2 runs on v19-e887c4b570. Writes v19a.done.
cd ~/oot-bc250-tests; rm -f v19a.done
run() { L=$1 B=$2 E=$3; systemd-run --user --collect --unit=rh-$L /bin/bash ~/oot-bc250-tests/reclaimhelper.sh >/dev/null
  bash ./withtest.sh ./routerun.sh castle2 $L $B "$E"; sleep 10; }
run castle2-sv1 v19-e887c4b570 "EDEN_NX2_FAST_DRAW_VERIFY=1;EDEN_NX2_GPU_PROFILE=1"
run castle2-sa1 v19-e887c4b570 ""
run castle2-sa2 v19-e887c4b570 ""
date > v19a.done
