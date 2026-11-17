#!/bin/bash
# oot-castle2.sh <label>: castle route v2 (save set castle-set). Like oot-castle.sh, but the plaza phases walk straight
# for PLAZAWALK s (default 12 = in the crowd by the fountain; calibrated with oot-castlecal.sh: past ~16 s Link leaves the plaza northwards, 24+ s reaches the castle-grounds exit and the owl) into the middle of the plaza, then spin the camera right and back left in place (the
# camera ends where it started, so the walk out retraces the way in).
R=castle2 L=$1; . ~/oot-bc250-tests/oot-routelib.sh
PW=${PLAZAWALK:-12}
load; mark start
walk 0 1 ${IN1:-8};  mark in1;  sleep ${LOADWAIT:-60}; mark town1
walk 0 1 $PW; mark centre1; spin 1 8; spin -1 8; mark plaza1
walk 0 -1 $(( PW + ${OUTEXTRA:-12} )); mark out1; sleep ${LOADWAIT:-60}; mark field1
walk 0 -1 ${IN2:-8}; mark in2; sleep ${LOADWAIT:-60}; mark town2
walk 0 1 $PW; mark centre2; spin 1 8; spin -1 8; mark plaza2
echo "end $(up)" >> long-$L.txt
