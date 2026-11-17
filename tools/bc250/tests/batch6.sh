#!/bin/bash
# batch6.sh <tag> [env] [runs]: candidate build, stutter trace on, walk metrics.
cd ~/oot-bc250-tests
BIN=${BIN6:-${BC250_HOME:-$HOME}/Applications/eden-bins/fr-0293de816a/eden-cli}
for r in $(seq ${3:-2}); do
  L=$1-$r; rm -f shot-$L-*
  systemd-run --user --unit=vms-$L --collect ~/oot-bc250-tests/vmsnap.sh $L >/dev/null
  BIN=$BIN ./ab-run.sh $L "EDEN_NX2_STUTTER_TRACE=1${2:+;$2}" 2>&1 | grep -E "fps|samples" >> batch6.txt
  cp ~/.local/share/eden/log/eden_log.txt log-$L.txt; sleep 2
  python3 -I walkstats.py $L >> batch6.txt 2>&1
done
