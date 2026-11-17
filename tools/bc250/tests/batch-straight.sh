#!/bin/bash
# batch-straight.sh: A/B on the straight walk (2026-11-10 night). Results in batch-straight.txt.
cd ~/oot-bc250-tests
NEW=${BC250_HOME:-$HOME}/lichii-bc250-dev/build/bin/eden-cli
OLD=${BC250_HOME:-$HOME}/oot-bc250/build/bin/eden-cli
MROFF=$'pin_gpu_threads=true;1\\disabled\\size=1\n1\\disabled\\1\\d=Max Resolution (built-in)'
for r in 1 2; do
  for c in A B C D; do
    case $c in
      A) BIN=$NEW INI= NOFG= ;;
      B) BIN=$OLD INI= NOFG= ;;
      C) BIN=$NEW INI="$MROFF" NOFG= ;;
      D) BIN=$NEW INI= NOFG=1 ;;
    esac
    L=st-$c$r
    BIN=$BIN INI=$INI NOFG=$NOFG ./ab-run.sh $L "" 2>&1 | grep -E "fps|samples" >> batch-straight.txt
    grep -E "Applying built-in patch \"Max" ~/.local/share/eden/log/eden_log.txt | head -1 | sed "s/^.*Applying/  $L applying/" >> batch-straight.txt
  done
done
echo DONE >> batch-straight.txt
