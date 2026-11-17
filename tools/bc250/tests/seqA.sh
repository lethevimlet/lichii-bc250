#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
./castlerun.sh b196w v7-f75bbec369 "" > ${BC250_HOME:-$HOME}/oot-bc250-tests/b196w.out 2>&1
./castlerun.sh b196a v7-f75bbec369 "" > ${BC250_HOME:-$HOME}/oot-bc250-tests/b196a.out 2>&1
python3 castlestats.py b196a >> ${BC250_HOME:-$HOME}/oot-bc250-tests/b196a.out 2>&1
