#!/bin/bash
# memrun.sh <label> <bin> [env]: castle route with memtrack running alongside.
cd ${BC250_HOME:-$HOME}/oot-bc250-tests; L=$1; B=$2; ENVV=$3
[ -n "$NOTRACK" ] || ( ./memtrack.sh $L ) &
./castlerun.sh $L $B "$ENVV" > $L.out 2>&1
touch /tmp/memtrack-stop-$L
python3 castlestats.py $L >> $L.out 2>&1
wait
