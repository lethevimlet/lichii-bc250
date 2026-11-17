#!/bin/bash
# castlerun.sh <label> <bin-dir-name> [env]: castle route (oot-castle.sh) from the frozen castle save, with the 1 s memory
# sampler; stop, restore the owner's saves, copy the log, print per-10 s stats.
L=$1; B=$2; ENVV=$3; cd ~/oot-bc250-tests
export XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
until ! pgrep -x eden-cli >/dev/null; do sleep 2; done; sleep 5
systemctl --user reset-failed "oot-$L.service" "t1w-$L.service" 2>/dev/null
SAVE_SET=castle-set ./saveguard.sh test || exit 1
systemd-run --user --unit=t1w-$L --collect /bin/bash -c "until pgrep -x eden-cli >/dev/null; do sleep 1; done; exec ~/oot-bc250-tests/t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-$L.txt" >/dev/null
systemd-run --user --unit=oot-$L --setenv=BC250_RUN_SECONDS=900 \
  --setenv=BC250_TEST_BIN=${BC250_HOME:-$HOME}/Applications/eden-bins/$B/eden-cli \
  "--setenv=BC250_TEST_INI=${INI:-pin_gpu_threads=true;frame_gen_target_rate=0;frame_gen_queue_target=1}" \
  "--setenv=BC250_TEST_ENV=$ENVV" /usr/bin/python3 -I ~/oot-bc250-tests/bc250-watch.py >/dev/null
./oot-castle.sh $L
systemctl --user stop oot-$L
for i in $(seq 60); do pgrep -x eden-cli >/dev/null || break; sleep 1; done
./saveguard.sh restore
sleep 3
cp ~/.local/share/eden/log/eden_log.txt log-$L.txt
cat long-$L.txt | tr '\n' ' '; echo
