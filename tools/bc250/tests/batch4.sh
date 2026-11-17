#!/bin/bash
cd ~/oot-bc250-tests
REF=${BC250_HOME:-$HOME}/Applications/eden-bins/l150-4e20bbb518/eden-cli
NEW=${BC250_HOME:-$HOME}/lichii-bc250-dev/build/bin/eden-cli
OPT="EDEN_NX2_JIT_WARM=1;EDEN_NX2_EXP48=1;EDEN_NX2_IR_POOL_CAP_MIB=64"
run() {  # label bin env
  rm -f mem-$1.txt shot-$1-start.png
  systemd-run --user --unit=memw-$1 --collect ~/oot-bc250-tests/memwatch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/mem-$1.txt >/dev/null
  if [ "$4" = scan ]; then ( until [ -f shot-$1-start.png ]; do sleep 2; done; sleep 10; P=$(pgrep -x eden-cli); python3 -I zeroscan.py $P > zero-$1.txt 2>&1 ) & fi
  BIN=$2 ./ab-run.sh $1 "$3" 2>&1 | grep -E "fps|samples" >> batch4.txt
  wait
  awk "{for(i=1;i<=NF;i++) if(\$i==\"RssAnon:\") print \$(i+1)}" mem-$1.txt | sort -n | tail -1 | sed "s/^/  $1 max emulator RssAnon MB: /" >> batch4.txt
  [ -f zero-$1.txt ] && sed "s/^/  $1 zeroscan: /" zero-$1.txt >> batch4.txt
}
for r in 1 2; do
  run e48-$r $NEW "EDEN_NX2_EXP48=1"
  run warm-$r $NEW "EDEN_NX2_JIT_WARM=1"
  run irc-$r $NEW "EDEN_NX2_IR_POOL_CAP_MIB=64"
done
echo DONE >> batch4.txt
