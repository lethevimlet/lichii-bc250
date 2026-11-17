#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
for L in relw rel1; do
./castlerun.sh $L rel-rc2 "" > ${BC250_HOME:-$HOME}/oot-bc250-tests/$L.out 2>&1
python3 castlestats.py $L >> ${BC250_HOME:-$HOME}/oot-bc250-tests/$L.out 2>&1
done
