#!/bin/bash
# tlx.sh: castle2 timelines: tl-p1 captures the first plaza visit's spin, tl-p2 the second's. Writes tlx.done.
cd ~/oot-bc250-tests; rm -f tlx.done
run() { L=$1 M=$2; rm -f /tmp/nx2-timeline-go /tmp/tl-$L.json long-castle2-$L.txt
  ( until grep -q "^$M " long-castle2-$L.txt 2>/dev/null; do sleep 0.5; done; sleep 2; touch /tmp/nx2-timeline-go ) &
  systemd-run --user --collect --unit=rh-$L /bin/bash ~/oot-bc250-tests/reclaimhelper.sh >/dev/null
  bash ./withtest.sh ./routerun.sh castle2 castle2-$L v17-4fbde27eb7 "EDEN_NX2_GPU_PROFILE=1;EDEN_NX2_TIMELINE=/tmp/tl-$L.json;EDEN_NX2_TIMELINE_SECONDS=6"
  wait; rm -f /tmp/nx2-timeline-go; cp /tmp/tl-$L.json . 2>/dev/null; sleep 10; }
run p1 centre1; run p2 centre2
date > tlx.done
