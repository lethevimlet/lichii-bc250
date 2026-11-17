#!/bin/bash
# oot-castle.sh <label>: load the castle-entrance save (drawbridge, facing the gate), then: walk in (first entry = area
# load), wander the plaza, walk back out, come back in. Marks phases with the emulator uptime in long-<label>.txt and
# takes a gamescope screenshot per phase (shots/castle-<label>-<phase>.png) to check the route.
L=$1; cd ~/oot-bc250-tests || exit 1; mkdir -p shots
D() { ./dbg.sh "$@"; }
up() { P=$(pgrep -x eden-cli); ps -o etimes= -p $P | tr -d ' '; }
mark() { echo "$1 $(up)" >> long-$L.txt; DISPLAY=:0 gamescopectl screenshot ${BC250_HOME:-$HOME}/oot-bc250-tests/shots/castle-$L-$1.png >/dev/null 2>&1; }
walk() { D "{\"method\":\"input\",\"params\":{\"left_stick\":[$1,$2],\"frames\":3000,\"timeout_s\":$3}}" >/dev/null 2>&1; }
spin() { D "{\"method\":\"input\",\"params\":{\"right_stick\":[$1,0],\"frames\":3000,\"timeout_s\":$2}}" >/dev/null 2>&1; }
for i in $(seq 40); do pgrep -x eden-cli >/dev/null && break; sleep 3; done
for i in $(seq 120); do D '{"method":"status"}' 2>/dev/null | grep -q uptime && break; sleep 3; done
sleep ${TITLEWAIT:-40}
D '{"method":"input_sequence","params":{"steps":[{"buttons":["A"],"frames":4},{"buttons":[],"frames":60},{"buttons":["A"],"frames":4},{"buttons":[],"frames":40},{"buttons":["A"],"frames":4},{"buttons":[],"frames":4}],"timeout_s":30}}' >/dev/null
for try in $(seq ${LOADTRIES:-3}); do
  sleep 15
  [ $(( $(cat /sys/class/drm/card1/device/mem_info_gtt_used) >> 20 )) -gt 1500 ] && break
  D '{"method":"input_sequence","params":{"steps":[{"buttons":["A"],"frames":4},{"buttons":[],"frames":4}],"timeout_s":30}}' >/dev/null
done
sleep 20
: > long-$L.txt; mark start
walk 0 1 ${IN1:-8};  mark in1;  sleep ${LOADWAIT:-30}; mark town1
walk 0 1 10; spin 1 8; walk 0 1 8; spin -1 8; mark plaza1
walk 0 -1 ${OUT:-12}; mark out1; sleep ${LOADWAIT:-30}; mark field1
walk 0 -1 ${IN2:-8}; mark in2; sleep ${LOADWAIT:-30}; mark town2
walk 0 1 10; spin 1 8; walk 0 1 8; spin -1 8; mark plaza2
echo "end $(up)" >> long-$L.txt
