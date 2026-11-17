#!/bin/bash
cd ~/oot-bc250-tests
for n in 1 2; do rm -f long-castle2-pr$n.txt prereclaim-castle2-pr$n.txt
  systemd-run --user --collect --unit=prc-$n /bin/bash ~/oot-bc250-tests/prereclaim.sh castle2-pr$n 3 1536M >/dev/null
  ./routerun.sh castle2 castle2-pr$n v17-e4e80a8fa2 ""; sleep 10; done
