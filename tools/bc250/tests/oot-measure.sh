#!/bin/bash
# oot-measure.sh <label>: after a bc250-watch.py launch: load the latest save, then the owner's
# test (since 2026-11-10 22:30): walk straight ahead (left stick up) for 30 s, no turn, no ZL.
# fps = frames the game presented during the 30 s walk.
L=$1; cd ~/oot-bc250-tests || exit 1
SHOTS=${BC250_HOME:-$HOME}/oot-bc250-tests
LOG=~/.local/share/eden/log/eden_log.txt
D() { ./dbg.sh "$@"; }
for i in $(seq 40); do pgrep -x eden-cli >/dev/null && break; sleep 3; done
for i in $(seq 120); do D '{"method":"status"}' 2>/dev/null | grep -q uptime && break; sleep 3; done
sleep 40
D '{"method":"input_sequence","params":{"steps":[{"buttons":["A"],"frames":4},{"buttons":[],"frames":60},{"buttons":["A"],"frames":4},{"buttons":[],"frames":40},{"buttons":["A"],"frames":4},{"buttons":[],"frames":4}],"timeout_s":30}}' >/dev/null
for try in 1 2 3; do
  sleep 15
  [ $(( $(cat /sys/class/drm/card1/device/mem_info_gtt_used) >> 20 )) -gt 1500 ] && break
  D '{"method":"input_sequence","params":{"steps":[{"buttons":["A"],"frames":4},{"buttons":[],"frames":4}],"timeout_s":30}}' >/dev/null
done
sleep 30
D '{"method":"screenshot","params":{}}' $SHOTS/shot-$L-start.png >/dev/null
( sleep 8; python3 -I bc250-thread-sample.py > threads-$L.txt ) &
( sleep 10; python3 -I gpubusy.py 12 > gpu-$L.txt ) &
if [ -n "$PERF_THREAD" ]; then
  ( sleep 10; P=$(pgrep -x eden-cli); T=$(grep -lx "$PERF_THREAD" /proc/$P/task/*/comm | head -1 | cut -d/ -f5)
    distrobox enter bc250-meshbuild -- perf record -q -F 1999 -t $T -o ${BC250_HOME:-$HOME}/oot-bc250-tests/perf-$L.data -- sleep 12 >/dev/null 2>&1 ) &
fi
N=$(D '{"method":"input","params":{"left_stick":[0,1],"frames":3000,"timeout_s":30}}' 2>&1 | grep -oE '[0-9]+ of 3000 frames' | cut -d' ' -f1)
D '{"method":"screenshot","params":{}}' $SHOTS/shot-$L-end.png >/dev/null
if [ -n "$EXTRA" ]; then  # route 2: camera spins + walk back through the open forest
  X1=$(D '{"method":"input","params":{"right_stick":[1,0],"frames":3000,"timeout_s":12}}' 2>&1 | grep -oE "[0-9]+ of 3000" | cut -d" " -f1)
  X2=$(D '{"method":"input","params":{"left_stick":[0,-1],"frames":3000,"timeout_s":15}}' 2>&1 | grep -oE "[0-9]+ of 3000" | cut -d" " -f1)
  X3=$(D '{"method":"input","params":{"right_stick":[-1,0],"frames":3000,"timeout_s":12}}' 2>&1 | grep -oE "[0-9]+ of 3000" | cut -d" " -f1)
  D '{"method":"screenshot","params":{}}' $SHOTS/shot-$L-x.png >/dev/null
  XN=$(( ${X1:-0} + ${X2:-0} + ${X3:-0} ))
fi
wait
{
echo "$L: ${N:-?} frames in the 30 s walk = $(python3 -c "print(round(${N:-0}/30,1))") fps"
[ -n "$EXTRA" ] && echo "$L: route2 spin/back/spin $X1/$X2/$X3 frames = $(python3 -c "print(round(${XN:-0}/39,1))") fps"
head -6 threads-$L.txt; cat gpu-$L.txt
grep "Report: GPU thread per second" $LOG | tail -1 | tr '|' '\n' | grep -E "idle|split drain|writer wait|macro |push"
grep "GPU back thread per second" $LOG | tail -1 | tr '|' '\n' | awk 'match($0, / ([0-9.]+) ms/, m) && m[1] > 15'
} | tee $L.txt
