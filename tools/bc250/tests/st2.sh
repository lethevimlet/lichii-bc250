#!/bin/bash
cd ~/oot-bc250-tests
./routerun.sh kokiri kokiri-st1 v16-8eaac8305a "EDEN_NX2_STUTTER_TRACE=1"; sleep 10
./routerun.sh horse horse-st1 v16-8eaac8305a "EDEN_NX2_STUTTER_TRACE=1"
