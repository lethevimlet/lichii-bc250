#!/bin/bash
cd ~/oot-bc250-tests
./routerun.sh castle2 castle2-d1 v16-1f7248a988 "EDEN_NX2_STUTTER_TRACE=1"; sleep 10
./routerun.sh castle2 castle2-d2 v16-1f7248a988 ""; sleep 10
./routerun.sh horse horse-d1 v16-1f7248a988 ""; sleep 10
./routerun.sh kokiri kokiri-d1 v16-1f7248a988 ""; sleep 10
./routerun.sh kakariko kakariko-d1 v16-1f7248a988 ""
