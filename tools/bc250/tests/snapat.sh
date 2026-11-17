#!/bin/bash
# snapat.sh <label> <mark> <delay>: when long-<label>.txt shows <mark>, wait <delay> s and copy eden-cli smaps
L=$1; M=$2; D=$3; cd ${BC250_HOME:-$HOME}/oot-bc250-tests
until grep -q "^$M" long-$L.txt 2>/dev/null; do sleep 1; done; sleep $D
P=$(pgrep -x eden-cli) && cp /proc/$P/smaps smaps-$L.txt && grep -E "^(RssAnon|VmSwap)" /proc/$P/status > status-$L.txt
