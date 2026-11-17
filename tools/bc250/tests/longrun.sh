#!/bin/bash
# longrun.sh <label> <bin-dir-name> [env] [loops]: launch through bc250-watch (FG 2x, target 0, queue 1 unless INI
# overrides), run oot-long.sh, stop, copy the log, print longstats.
L=$1; B=$2; ENVV=$3; LOOPS=${4:-5}; cd ~/oot-bc250-tests
export XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
until ! pgrep -x eden-cli >/dev/null; do sleep 2; done; sleep 5
systemctl --user reset-failed "oot-$L.service" 2>/dev/null
./saveguard.sh test || exit 1
systemd-run --user --unit=oot-$L --setenv=BC250_RUN_SECONDS=900 \
  --setenv=BC250_TEST_BIN=${BC250_HOME:-$HOME}/Applications/eden-bins/$B/eden-cli \
  "--setenv=BC250_TEST_INI=${INI:-pin_gpu_threads=true;frame_gen_target_rate=0;frame_gen_queue_target=1}" \
  "--setenv=BC250_TEST_ENV=$ENVV" /usr/bin/python3 -I ~/oot-bc250-tests/bc250-watch.py >/dev/null
./oot-long.sh $L $LOOPS
systemctl --user stop oot-$L
for i in $(seq 60); do pgrep -x eden-cli >/dev/null || break; sleep 1; done
./saveguard.sh restore
sleep 3
cp ~/.local/share/eden/log/eden_log.txt log-$L.txt
python3 -I longstats.py $L
