#!/bin/bash
cd ~/oot-bc250-tests
run() { L=$1 D=$2 A=$3; rm -f long-castle2-$L.txt prereclaim-castle2-$L.txt
  systemd-run --user --collect --unit=prc-$L /bin/bash ~/oot-bc250-tests/prereclaim.sh castle2-$L $D $A >/dev/null
  ./routerun.sh castle2 castle2-$L v17-e4e80a8fa2 ""; sleep 10; }
run pr3 5 1536M; run pr4 5 1536M; run pr5 5 2560M
