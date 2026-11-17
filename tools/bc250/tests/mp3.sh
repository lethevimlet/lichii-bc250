#!/bin/bash
cd ~/oot-bc250-tests
./routerun.sh castle2 castle2-mp3 v16-91f31bc03e "EDEN_NX2_VMA_PEAK_DUMP=/tmp/vp-mp3.json"; cp /tmp/vp-mp3.json* . ; sleep 10
./routerun.sh horse horse-c1 v16-91f31bc03e ""; sleep 10
./routerun.sh kokiri kokiri-c1 v16-91f31bc03e ""; sleep 10
./routerun.sh kakariko kakariko-c1 v16-91f31bc03e ""
