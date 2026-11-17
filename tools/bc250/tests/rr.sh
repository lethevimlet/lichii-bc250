#!/bin/bash
cd ~/oot-bc250-tests
./routerun.sh horse horse-rr1 v16-fef02e99a8 "EDEN_NX2_TC_TRACE=1"; sleep 10
./routerun.sh horse horse-rr2 v16-fef02e99a8 ""; sleep 10
./routerun.sh kokiri kokiri-rr2 v16-fef02e99a8 ""
