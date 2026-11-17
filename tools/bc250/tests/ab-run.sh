#!/bin/bash
# ab-run.sh <label> [BC250_TEST_ENV value]: launch (fix + pinning), sample memory, owner's route
L=$1; ENVV=$2; cd ~/oot-bc250-tests
export XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
until ! pgrep -x eden-cli >/dev/null; do sleep 2; done; sleep 5
[ "$(grep -cE 'bc250-test|DEBUG_SERVER|mesh-cache' ~/Applications/Eglantine)" = 0 ] || { echo launcher-dirty; exit 1; }
systemctl --user reset-failed "oot-$L.service" "oot-s-$L.service" 2>/dev/null
rm -f fps-$L.log
./saveguard.sh test || exit 1
systemd-run --user --unit=oot-$L --setenv=BC250_RUN_SECONDS=600 \
  --setenv=BC250_TEST_BIN=${BIN:-${BC250_HOME:-$HOME}/oot-bc250-mesh-cache-test/build2/bin/eden-cli} \
  "--setenv=BC250_TEST_INI=${INI:-pin_gpu_threads=true}" "--setenv=BC250_TEST_ENV=$ENVV" "--setenv=BC250_TEST_RES=${RES:-}" "--setenv=BC250_TEST_NOFG=${NOFG:-}" "--setenv=BC250_TEST_BASE_INI=${BASEINI:-}" \
  /usr/bin/python3 -I ~/oot-bc250-tests/bc250-watch.py >/dev/null
systemd-run --user --unit=oot-s-$L --property=RuntimeMaxSec=700 ~/oot-bc250-tests/fps-sampler.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/fps-$L.log >/dev/null
./oot-measure.sh $L | head -2
python3 -I memsum.py fps-$L.log
systemctl --user stop oot-$L oot-s-$L
for i in $(seq 60); do pgrep -x eden-cli >/dev/null || break; sleep 1; done
./saveguard.sh restore
