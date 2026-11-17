#!/bin/bash
# bootmem.sh <label> <bin-dir> <env> <secs>: launch, no input, sample eden-cli private memory every 5 s, stop.
L=$1; B=$2; ENVV=$3; S=${4:-360}; cd ${BC250_HOME:-$HOME}/oot-bc250-tests
export XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
until ! pgrep -x eden-cli >/dev/null; do sleep 2; done; sleep 5
systemctl --user reset-failed "oot-$L.service" 2>/dev/null
SAVE_SET=castle-set ./saveguard.sh test || exit 1
systemd-run --user --unit=oot-$L --setenv=BC250_RUN_SECONDS=$((S+60)) \
  --setenv=BC250_TEST_BIN=${BC250_HOME:-$HOME}/Applications/eden-bins/$B/eden-cli \
  "--setenv=BC250_TEST_INI=pin_gpu_threads=true;frame_gen_target_rate=0;frame_gen_queue_target=1" \
  "--setenv=BC250_TEST_ENV=$ENVV" /usr/bin/python3 -I ~/oot-bc250-tests/bc250-watch.py >/dev/null
: > bm-$L.txt
for i in $(seq 120); do pgrep -x eden-cli >/dev/null && break; sleep 2; done
P=$(pgrep -x eden-cli); t=0
while [ $t -lt $S ] && [ -d /proc/$P ]; do
  awk -v t=$t "/^(RssAnon|VmSwap):/{s+=\$2} END{printf \"%d %d\n\", t, s/1024}" /proc/$P/status >> bm-$L.txt; sleep 5; t=$((t+5)); done
systemctl --user stop oot-$L; for i in $(seq 60); do pgrep -x eden-cli >/dev/null || break; sleep 1; done
./saveguard.sh restore; sleep 3; cp ~/.local/share/eden/log/eden_log.txt log-$L.txt
echo "$L: private at end $(tail -1 bm-$L.txt | cut -d" " -f2) MB, max $(sort -k2 -n bm-$L.txt | tail -1 | cut -d" " -f2) MB"
