#!/bin/bash
# coldcastle.sh <label> <bin> <env>: castle route with an empty OoT shader cache (moved aside, restored after),
# thread nice/CPU snapshot 60 s into the game.
L=$1; B=$2; ENVV=$3; cd ~/oot-bc250-tests
C=~/.cache/eden/shader; T=$C/0400486024dec000
until ! pgrep -x eden-cli >/dev/null; do sleep 2; done
[ -e $T.warm ] && { echo "warm cache already aside"; exit 1; }
mv $T $T.warm && mkdir $T
( until pgrep -x eden-cli >/dev/null; do sleep 1; done; sleep 120; P=$(pgrep -x eden-cli | tail -1)
  ps -L -o tid,ni,pri,pcpu,comm -p $P --sort=-pcpu | head -40 > threads-$L.txt ) &
TITLEWAIT=200 LOADTRIES=14 LOADWAIT=60 ./castlerun.sh $L $B "$ENVV" > $L.out 2>&1
python3 castlestats.py $L >> $L.out 2>&1
wait
until ! pgrep -x eden-cli >/dev/null; do sleep 2; done
rm -rf $T.cold-$L; mv $T $T.cold-$L; mv $T.warm $T
