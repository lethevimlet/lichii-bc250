#!/bin/bash
# oot-idle.sh <label>: load the save, then no input for IDLE s (default 900) so a person can play or change Steam settings.
R=idle L=$1; . ~/oot-bc250-tests/oot-routelib.sh
load; mark start
sleep ${IDLE:-900}
echo "end $(up)" >> long-$L.txt
