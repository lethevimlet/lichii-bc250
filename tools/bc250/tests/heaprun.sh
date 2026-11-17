#!/bin/bash
# heaprun.sh: launch under heaptrack (ht/eden-cli), load the save patiently, walk, stop.
cd ~/oot-bc250-tests
export XDG_RUNTIME_DIR=/run/user/1000
D() { ./dbg.sh "$@"; }
gtt() { echo $(( $(cat /sys/class/drm/card1/device/mem_info_gtt_used) >> 20 )); }
for i in $(seq 60); do pgrep -f "[S]teamLaunch AppId=3688079378" >/dev/null || pgrep -x eden-cli >/dev/null || break; sleep 5; done; pgrep -x eden-cli && { echo game-still-running; exit 1; }
systemctl --user reset-failed
systemd-run --user --unit=oot-heap3 --setenv=BC250_RUN_SECONDS=1500 \
  --setenv=BC250_TEST_BIN=${BC250_HOME:-$HOME}/oot-bc250-tests/ht/eden-cli \
  --setenv=BC250_TEST_INI=pin_gpu_threads=true /usr/bin/python3 -I ~/oot-bc250-tests/bc250-watch.py >/dev/null
for i in $(seq 100); do pgrep -x eden-cli >/dev/null && break; sleep 3; done
for i in $(seq 200); do D '{"method":"status"}' 2>/dev/null | grep -q uptime && break; sleep 3; done
echo "debug server up $(date +%T)"
sleep 120
for i in $(seq 40); do
  [ $(gtt) -gt 1500 ] && break
  D '{"method":"input_sequence","params":{"steps":[{"buttons":["A"],"frames":4},{"buttons":[],"frames":30}],"timeout_s":30}}' >/dev/null
  sleep 8
done
echo "in game $(date +%T) gtt $(gtt)"
sleep 60
D '{"method":"input","params":{"left_stick":[0,1],"frames":3000,"timeout_s":40}}' >/dev/null
sleep 20
P=$(pgrep -x eden-cli); grep -E "^(RssAnon|VmSwap)" /proc/$P/status
D '{"method":"screenshot","params":{}}' ${BC250_HOME:-$HOME}/oot-bc250-tests/shot-heap3.png >/dev/null
systemctl --user stop oot-heap3
sleep 20; ls -la ht/
