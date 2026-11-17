#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
./castlerun.sh v7rel3 rel-v7 "" > ${BC250_HOME:-$HOME}/oot-bc250-tests/v7rel3.out 2>&1
python3 castlestats.py v7rel3 >> ${BC250_HOME:-$HOME}/oot-bc250-tests/v7rel3.out 2>&1
