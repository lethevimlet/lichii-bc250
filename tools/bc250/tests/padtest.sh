#!/bin/bash
# padtest.sh <label> <bin>: boot from the castle test save with no bound pad present; a virtual Bluetooth pad
# (unknown vendor, so Steam Input leaves it alone) presses START then EAST (Switch A) at the title.
L=$1; B=$2; cd ~/oot-bc250-tests
export XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
until ! pgrep -x eden-cli >/dev/null; do sleep 2; done; sleep 3
rm -f /tmp/pad-go-* /tmp/pad-done-*
SAVE_SET=castle-set ./saveguard.sh test || exit 1
systemctl --user reset-failed oot-$L 2>/dev/null
systemd-run --user --unit=oot-$L --setenv=BC250_RUN_SECONDS=400 \
  --setenv=BC250_TEST_BIN=${BC250_HOME:-$HOME}/Applications/eden-bins/$B/eden-cli \
  "--setenv=BC250_TEST_INI=pin_gpu_threads=true" /usr/bin/python3 -I ~/oot-bc250-tests/bc250-watch.py >/dev/null
until pgrep -x eden-cli >/dev/null; do sleep 1; done
sleep 150
shot() { DISPLAY=:0 gamescopectl screenshot ${BC250_HOME:-$HOME}/oot-bc250-tests/shots/pad-$L-$1.png >/dev/null 2>&1; }
shot 0-title
touch /tmp/pad-go-1; until [ -e /tmp/pad-done-1 ]; do sleep 1; done
shot 1-after-start
touch /tmp/pad-go-2; until [ -e /tmp/pad-done-2 ]; do sleep 1; done
shot 2-after-a
sleep 20; shot 3-later
systemctl --user stop oot-$L
for i in $(seq 60); do pgrep -x eden-cli >/dev/null || break; sleep 1; done
./saveguard.sh restore
sleep 3; cp ~/.local/share/eden/log/eden_log.txt log-$L.txt
