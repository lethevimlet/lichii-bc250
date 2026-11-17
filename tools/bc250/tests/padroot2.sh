#!/bin/bash
# padroot2.sh <label> (root): one virtual pad for the whole test: created now, taps at the title (~170 s in).
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
PADVID=0x1234 PADPID=0x5678 python3 -I fakepad.py "wait 200; tap EAST; wait 10; tap EAST; wait 10; tap EAST; wait 30" >> pad-$1.out 2>&1
