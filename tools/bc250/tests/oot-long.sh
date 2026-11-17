#!/bin/bash
# oot-long.sh <label> [loops]: load the save, then loop (walk 15 s, spin right 12 s, walk back 15 s,
# spin left 12 s) ~54 s per loop, default 5 loops (~4.5 min). Marks start/loop/end in long-<label>.txt
# with the emulator uptime so the log's 10 s "Screen:" / "Frame gen output" lines can be split.
L=$1; LOOPS=${2:-5}; cd ~/oot-bc250-tests || exit 1
D() { ./dbg.sh "$@"; }
up() { P=$(pgrep -x eden-cli); ps -o etimes= -p $P | tr -d ' '; }
for i in $(seq 40); do pgrep -x eden-cli >/dev/null && break; sleep 3; done
for i in $(seq 120); do D '{"method":"status"}' 2>/dev/null | grep -q uptime && break; sleep 3; done
sleep ${TITLEWAIT:-40}
D '{"method":"input_sequence","params":{"steps":[{"buttons":["A"],"frames":4},{"buttons":[],"frames":60},{"buttons":["A"],"frames":4},{"buttons":[],"frames":40},{"buttons":["A"],"frames":4},{"buttons":[],"frames":4}],"timeout_s":30}}' >/dev/null
for try in $(seq ${LOADTRIES:-3}); do
  sleep 15
  [ $(( $(cat /sys/class/drm/card1/device/mem_info_gtt_used) >> 20 )) -gt 1500 ] && break
  D '{"method":"input_sequence","params":{"steps":[{"buttons":["A"],"frames":4},{"buttons":[],"frames":4}],"timeout_s":30}}' >/dev/null
done
sleep 30
echo "start $(up)" > long-$L.txt
for i in $(seq $LOOPS); do
  D '{"method":"input","params":{"left_stick":[0,1],"frames":3000,"timeout_s":15}}' >/dev/null 2>&1
  D '{"method":"input","params":{"right_stick":[1,0],"frames":3000,"timeout_s":12}}' >/dev/null 2>&1
  D '{"method":"input","params":{"left_stick":[0,-1],"frames":3000,"timeout_s":15}}' >/dev/null 2>&1
  D '{"method":"input","params":{"right_stick":[-1,0],"frames":3000,"timeout_s":12}}' >/dev/null 2>&1
  echo "loop$i $(up)" >> long-$L.txt
done
echo "end $(up)" >> long-$L.txt
