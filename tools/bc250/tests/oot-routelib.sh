#!/bin/bash
# oot-routelib.sh: shared helpers for the route scripts (source it with R=<route> L=<label> set).
# D = debug server call; mark <phase> = emulator uptime into long-$L.txt + gamescope screenshot shots/$R-$L-<phase>.png;
# load = wait for the title, Continue, retry A until the area is loaded (GTT > 1.5 GB), settle 20 s.
cd ~/oot-bc250-tests || exit 1; mkdir -p shots
D() { ./dbg.sh "$@"; }
up() { P=$(pgrep -x eden-cli); ps -o etimes= -p $P | tr -d ' '; }
mark() { echo "$1 $(up)" >> long-$L.txt; DISPLAY=:0 gamescopectl screenshot ${BC250_HOME:-$HOME}/oot-bc250-tests/shots/$R-$L-$1.png >/dev/null 2>&1; }
walk() { D "{\"method\":\"input\",\"params\":{\"left_stick\":[$1,$2],\"frames\":3000,\"timeout_s\":$3}}" >/dev/null 2>&1; }
spin() { D "{\"method\":\"input\",\"params\":{\"right_stick\":[$1,0],\"frames\":3000,\"timeout_s\":$2}}" >/dev/null 2>&1; }
walkspin() { D "{\"method\":\"input\",\"params\":{\"left_stick\":[0,1],\"right_stick\":[$1,0],\"frames\":3000,\"timeout_s\":$2}}" >/dev/null 2>&1; }
# ride <seconds> <camera -1|0|1>: hold forward (+ camera spin), spur with A every 1.5 s. Frame-counted steps (game
# presents); the timeout bounds the wall time.
ride() {
  local n=$(( $1 * 2 / 3 )) steps=""
  for i in $(seq $n); do
    steps="$steps{\"buttons\":[\"A\"],\"left_stick\":[0,1],\"right_stick\":[$2,0],\"frames\":4},{\"buttons\":[],\"left_stick\":[0,1],\"right_stick\":[$2,0],\"frames\":41},"
  done
  D "{\"method\":\"input_sequence\",\"params\":{\"steps\":[${steps%,}],\"timeout_s\":$(( $1 * 3 + 10 ))}}" >/dev/null 2>&1
}
load() {
  for i in $(seq 40); do pgrep -x eden-cli >/dev/null && break; sleep 3; done
  for i in $(seq 120); do D '{"method":"status"}' 2>/dev/null | grep -q uptime && break; sleep 3; done
  sleep ${TITLEWAIT:-150}
  D '{"method":"input_sequence","params":{"steps":[{"buttons":["A"],"frames":4},{"buttons":[],"frames":60},{"buttons":["A"],"frames":4},{"buttons":[],"frames":40},{"buttons":["A"],"frames":4},{"buttons":[],"frames":4}],"timeout_s":30}}' >/dev/null
  for try in $(seq ${LOADTRIES:-12}); do
    sleep 15
    [ $(( $(cat /sys/class/drm/card1/device/mem_info_gtt_used) >> 20 )) -gt 1500 ] && break
    D '{"method":"input_sequence","params":{"steps":[{"buttons":["A"],"frames":4},{"buttons":[],"frames":4}],"timeout_s":30}}' >/dev/null
  done
  sleep 20
  : > long-$L.txt
}
