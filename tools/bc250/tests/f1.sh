#!/bin/bash
cd ~/oot-bc250-tests
./routerun.sh kokiri kokiri-f1 v16-e6207b08ea ""; sleep 10
./routerun.sh horse horse-f1 v16-e6207b08ea ""; sleep 10
./routerun.sh kakariko kakariko-f1 v16-e6207b08ea ""
