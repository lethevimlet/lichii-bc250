#!/bin/bash
cd ~/oot-bc250-tests
./routerun.sh castle2 castle2-mf1 v17-42b5b28a9d "EDEN_NX2_STUTTER_TRACE=1"; sleep 10
./routerun.sh castle2 castle2-mf2 v17-42b5b28a9d ""; sleep 10
./routerun.sh castle2 castle2-mf3 v17-42b5b28a9d ""
