#!/bin/bash
# padtest3.sh <label> <bin> [late]: game started OUTSIDE Steam with Steam's virtual pad hidden from SDL; a virtual
# Bluetooth pad (padroot2.sh/padroot3.sh, started separately as root) presses EAST at the title. Debug-server
# screenshots before/after. "late": the pad appears after the game is up (hotplug).
L=$1; B=$2; cd ~/oot-bc250-tests
export XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
until ! pgrep -x eden-cli >/dev/null; do sleep 2; done; sleep 2
SAVE_SET=castle-set ./saveguard.sh test || exit 1
G="${BC250_HOME:-$HOME}/Games/switch2/The Legend of Zelda Ocarina of Time [0400486024dec000][v131072].nup"
systemd-run --user --collect --unit=direct-$L --setenv=DISPLAY=:1 --setenv=DISABLE_BGFX=1 \
  --setenv=SDL_GAMECONTROLLER_IGNORE_DEVICES=0x28de/0x11ff --setenv=XDG_RUNTIME_DIR=/run/user/1000 \
  --setenv=EDEN_NX2_DEBUG_SERVER=127.0.0.1:6545 --setenv=EDEN_NX2_TC_EXPECTED_MIB=1536 --setenv=EDEN_NX2_TC_CRITICAL_MIB=2048 \
  --setenv=EDEN_NX2_VSYNC_HZ=30 --setenv=EDEN_NX2_SWAP_INTERVAL=2 --setenv=EDEN_VI2_MAX_RESOLUTION_MODE=1 \
  --setenv=EDEN_NX2_SPLIT=2 --setenv=EDEN_NX2_FENCE_BATCH=1 --setenv=EDEN_NX2_FRAMES_AHEAD=2 \
  distrobox enter bc250-meshbuild -- ${BC250_HOME:-$HOME}/Applications/eden-bins/$B/eden-cli \
  -c ${BC250_HOME:-$HOME}/Applications/lichii-bc250/oot.ini -f -g "$G" >/dev/null
until pgrep -x eden-cli >/dev/null; do sleep 1; done
sleep 190
./dbg.sh '{"method":"screenshot","params":{}}' ${BC250_HOME:-$HOME}/oot-bc250-tests/shots/pad3-$L-before.png >/dev/null 2>&1
sleep 40
./dbg.sh '{"method":"screenshot","params":{}}' ${BC250_HOME:-$HOME}/oot-bc250-tests/shots/pad3-$L-after.png >/dev/null 2>&1
sleep 5
pkill -TERM -x eden-cli; for i in $(seq 60); do pgrep -x eden-cli >/dev/null || break; sleep 1; done
pgrep -x eden-cli && pkill -KILL -x eden-cli
sleep 2; ./saveguard.sh restore; sleep 2; cp ~/.local/share/eden/log/eden_log.txt log-$L.txt
grep -E "Controller connected|Controller removed|stands in|Stand-in" log-$L.txt | sed -E "s/^\[ *([0-9.]+)\][^:]*:[0-9]+:/\1 /" | cut -c1-230
