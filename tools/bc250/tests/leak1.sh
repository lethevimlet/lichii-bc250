#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
( ./t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-leak1.txt ) &
./longrun.sh leak1 v7-3010d23c35 "" 13 > ${BC250_HOME:-$HOME}/oot-bc250-tests/leak1.out 2>&1
wait
