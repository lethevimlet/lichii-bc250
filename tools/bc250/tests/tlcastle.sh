#!/bin/bash
# tlcastle.sh <label> <mark> [delay]: touch the timeline trigger <delay> s after <mark> in long-<label>.txt
L=$1; M=$2; W=${3:-8}; cd ${BC250_HOME:-$HOME}/oot-bc250-tests; rm -f /tmp/nx2-timeline-go
until grep -q "^$M " long-$L.txt 2>/dev/null; do sleep 1; done; sleep $W; touch /tmp/nx2-timeline-go
