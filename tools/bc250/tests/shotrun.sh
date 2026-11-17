#!/bin/bash
# shotrun.sh <label> <bin> <env> <loops> [cold]: Hyrule long route with a gamescope screenshot every 10 s.
L=$1; B=$2; ENVV=$3; LOOPS=$4; COLD=$5; cd ~/oot-bc250-tests
C=~/.cache/eden/shader
if [ -n "$COLD" ]; then rm -rf "$C/0400486024dec000.cold-$L"; mv "$C/0400486024dec000" "$C/0400486024dec000.cold-$L"; mkdir "$C/0400486024dec000"; fi
( until pgrep -x eden-cli >/dev/null; do sleep 1; done; i=0
  while pgrep -x eden-cli >/dev/null; do sleep 10; i=$((i+1)); DISPLAY=:0 gamescopectl screenshot ${BC250_HOME:-$HOME}/oot-bc250-tests/shots/hy-$L-$(printf %03d $i).png >/dev/null 2>&1; done ) &
./longrun.sh $L $B "$ENVV" $LOOPS > $L.out 2>&1
wait
grep -c format_lookup_table log-$L.txt > $L.asserts
