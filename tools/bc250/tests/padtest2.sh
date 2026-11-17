#!/bin/bash
# padtest2.sh <label> <bin>: like padtest.sh but the game starts OUTSIDE Steam (no Steam Input), launcher env,
# installer oot.ini; screenshots from the emulator's debug server.
L=$1; B=$2; cd ~/oot-bc250-tests
export XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
until ! pgrep -x eden-cli >/dev/null; do sleep 2; done; sleep 3
rm -f /tmp/pad-go-* /tmp/pad-done-*
SAVE_SET=castle-set ./saveguard.sh test || exit 1
G="${BC250_HOME:-$HOME}/Games/switch2/The Legend of Zelda Ocarina of Time [0400486024dec000][v131072].nup"
systemd-run --user --collect --unit=direct-$L --setenv=DISPLAY=:1 --setenv=DISABLE_BGFX=1 --setenv=SDL_GAMECONTROLLER_IGNORE_DEVICES=0x28de/0x11ff --setenv=XDG_RUNTIME_DIR=/run/user/1000 \
  --setenv=EDEN_NX2_DEBUG_SERVER=127.0.0.1:6545 --setenv=EDEN_NX2_TC_EXPECTED_MIB=1536 --setenv=EDEN_NX2_TC_CRITICAL_MIB=2048 \
  --setenv=EDEN_NX2_VSYNC_HZ=30 --setenv=EDEN_NX2_SWAP_INTERVAL=2 --setenv=EDEN_VI2_MAX_RESOLUTION_MODE=1 \
  --setenv=EDEN_NX2_SPLIT=2 --setenv=EDEN_NX2_FENCE_BATCH=1 --setenv=EDEN_NX2_FRAMES_AHEAD=2 \
  --setenv=EDEN_NX2_PIPELINE_WORKERS=4 --setenv=EDEN_NX2_PIPELINE_DRIVER_THREADS=2 --setenv=EDEN_NX2_IR_POOL_CAP_MIB=64 \
  distrobox enter bc250-meshbuild -- ${BC250_HOME:-$HOME}/Applications/eden-bins/$B/eden-cli \
  -c ${BC250_HOME:-$HOME}/Applications/lichii-bc250/oot.ini -f -g "$G" >/dev/null
until pgrep -x eden-cli >/dev/null; do sleep 1; done
sleep 150
D() { ./dbg.sh "$@"; }
D '{"method":"screenshot","params":{}}' ${BC250_HOME:-$HOME}/oot-bc250-tests/shots/pad2-$L-0-title.png >/dev/null
touch /tmp/pad-go-1; until [ -e /tmp/pad-done-1 ]; do sleep 1; done
D '{"method":"screenshot","params":{}}' ${BC250_HOME:-$HOME}/oot-bc250-tests/shots/pad2-$L-1-after-start.png >/dev/null
touch /tmp/pad-go-2; until [ -e /tmp/pad-done-2 ]; do sleep 1; done
D '{"method":"screenshot","params":{}}' ${BC250_HOME:-$HOME}/oot-bc250-tests/shots/pad2-$L-2-after-a.png >/dev/null
sleep 3
pkill -TERM -x eden-cli
for i in $(seq 60); do pgrep -x eden-cli >/dev/null || break; sleep 1; done
pgrep -x eden-cli && pkill -KILL -x eden-cli
sleep 2; ./saveguard.sh restore
sleep 2; cp ~/.local/share/eden/log/eden_log.txt log-$L.txt
