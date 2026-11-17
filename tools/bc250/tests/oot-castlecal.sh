#!/bin/bash
# oot-castlecal.sh <label>: castle entry, then the plaza walk in 2 s steps with a screenshot each (calibration).
R=castlecal L=$1; . ~/oot-bc250-tests/oot-routelib.sh
load; mark start
walk 0 1 8; mark in1; sleep 45; mark town1
for s in $(seq 2 2 24); do walk 0 1 2; mark w$s; done
echo "end $(up)" >> long-$L.txt
