#!/bin/bash
# padroot3.sh <label> (root): hotplug variant: the pad appears ~170 s after the game, taps EAST three times.
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
until pgrep -x eden-cli >/dev/null; do sleep 1; done; sleep 170
PADVID=0x1234 PADPID=0x5678 python3 -I fakepad.py "wait 15; tap EAST; wait 10; tap EAST; wait 10; tap EAST; wait 30" >> pad-$1.out 2>&1
