#!/bin/bash
cd ~/oot-bc250-tests
for n in 1 2 3; do echo "== ar$n $(date +%T)" >> reclaimhelper.log
  systemd-run --user --collect --unit=rh-ar$n /bin/bash ~/oot-bc250-tests/reclaimhelper.sh >/dev/null
  ./routerun.sh castle2 castle2-ar$n v17-75e9f1b8ae ""; sleep 10; done
