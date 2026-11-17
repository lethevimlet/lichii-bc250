#!/bin/bash
# vprun.sh <label> <bin-dir>: castle run with a VMA peak dump
cd ${BC250_HOME:-$HOME}/oot-bc250-tests; L=$1; B=$2
./castlerun.sh $L $B "EDEN_NX2_VMA_PEAK_DUMP=/tmp/vp-$L.json" > ${BC250_HOME:-$HOME}/oot-bc250-tests/$L.out 2>&1
python3 castlestats.py $L >> ${BC250_HOME:-$HOME}/oot-bc250-tests/$L.out 2>&1
cp /tmp/vp-$L.json* ${BC250_HOME:-$HOME}/oot-bc250-tests/ 2>/dev/null
