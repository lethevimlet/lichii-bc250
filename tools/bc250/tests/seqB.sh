#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
./castlerun.sh b196p6 v7-f75bbec369 "" > ${BC250_HOME:-$HOME}/oot-bc250-tests/b196p6.out 2>&1
python3 castlestats.py b196p6 >> ${BC250_HOME:-$HOME}/oot-bc250-tests/b196p6.out 2>&1
