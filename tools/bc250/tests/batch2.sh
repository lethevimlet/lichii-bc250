#!/bin/bash
cd ~/oot-bc250-tests
NEW=${BC250_HOME:-$HOME}/lichii-bc250-dev/build/bin/eden-cli
for L in st-C3 st-C4; do
  BIN=$NEW BASEINI=${BC250_HOME:-$HOME}/oot-bc250-tests/mr-off.ini ./ab-run.sh $L "" 2>&1 | grep -E "fps|samples" >> batch2.txt
  grep -cE "Applying built-in patch \"Max" ~/.local/share/eden/log/eden_log.txt | sed "s/^/  $L max-res patches applied: /" >> batch2.txt
done
BIN=$NEW ./ab-run.sh st-trace "EDEN_NX2_STUTTER_TRACE=1" 2>&1 | grep -E "fps|samples" >> batch2.txt
cp ~/.local/share/eden/log/eden_log.txt log-st-trace.txt
echo DONE >> batch2.txt
