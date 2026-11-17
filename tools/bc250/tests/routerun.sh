#!/bin/bash
# routerun.sh <route> <label> <bin-dir-name> [env]: run route oot-<route>.sh from its frozen save set with the 1 s memory
# sampler, stop, restore the owner's saves, copy the log, print the marks. Stats: castlestats.py <label>.
# Routes / save sets: horse -> hyrule-horse-set, castle2 -> castle-set (add kakariko / kokiri when their saves exist).
RT=$1 L=$2 B=$3 ENVV=$4; cd ~/oot-bc250-tests
case $RT in horse) SET=hyrule-horse-set;; castle|castle2|castlecal) SET=castle-set;; kakariko) SET=kakariko-set;; idle) SET=${SAVE_SET:-kokiri-set};; kokiri) SET=kokiri-set;; *) SET=${SAVE_SET:?no save set for $RT};; esac
export XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
while [ -e ~/oot-bc250-tests/PAUSED ] || pgrep -x eden-cli >/dev/null; do sleep 5; done; sleep 5
systemctl --user reset-failed "oot-$L.service" "t1w-$L.service" 2>/dev/null
SAVE_SET=$SET ./saveguard.sh test || exit 1
systemd-run --user --unit=t1w-$L --collect /bin/bash -c "until pgrep -x eden-cli >/dev/null; do sleep 1; done; exec ~/oot-bc250-tests/t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-$L.txt" >/dev/null
systemd-run --user --unit=oot-$L --setenv=BC250_RUN_SECONDS=900 \
  --setenv=BC250_TEST_BIN=${BC250_HOME:-$HOME}/Applications/eden-bins/$B/eden-cli \
  "--setenv=BC250_TEST_INI=${INI:-pin_gpu_threads=true;frame_gen_target_rate=0;frame_gen_queue_target=1}" \
  "--setenv=BC250_TEST_ENV=$ENVV" /usr/bin/python3 -I ~/oot-bc250-tests/bc250-watch.py >/dev/null
for i in $(seq 90); do pgrep -x eden-cli >/dev/null && break
  systemctl --user is-failed -q oot-$L && { echo "launch failed (see journalctl --user -u oot-$L)"; ./saveguard.sh restore; exit 1; }; sleep 2; done
pgrep -x eden-cli >/dev/null || { echo "no eden-cli after 180 s"; systemctl --user stop oot-$L; ./saveguard.sh restore; exit 1; }
./oot-$RT.sh $L
systemctl --user stop oot-$L
for i in $(seq 60); do pgrep -x eden-cli >/dev/null || break; sleep 1; done
./saveguard.sh restore
sleep 3
cp ~/.local/share/eden/log/eden_log.txt log-$L.txt
cat long-$L.txt | tr '\n' ' '; echo
