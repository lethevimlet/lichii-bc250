#!/bin/bash
# padroot.sh <label> (root): plays the virtual pad when padtest.sh asks (/tmp/pad-go-N), logs to pad-<label>.out
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
for n in 1 2; do
  until [ -e /tmp/pad-go-$n ]; do sleep 1; done
  if [ $n = 1 ]; then s="wait 4; tap START; wait 4"; else s="wait 4; tap EAST; wait 6"; fi
  PADVID=0x1234 PADPID=0x5678 python3 -I fakepad.py "$s" >> pad-$1.out 2>&1
  touch /tmp/pad-done-$n
done
