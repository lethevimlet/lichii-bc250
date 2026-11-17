#!/bin/bash
# nowdump.sh <label> <vma path> <mark>:<delay> ...: touch <vma path>.now <delay> s after each route mark.
L=$1 V=$2; shift 2; cd ~/oot-bc250-tests
for md in "$@"; do m=${md%%:*} d=${md##*:}
  until grep -q "^$m [0-9]" long-$L.txt 2>/dev/null; do sleep 1; done; sleep $d; touch $V.now; echo "$m+$d $(date +%T)"; done
