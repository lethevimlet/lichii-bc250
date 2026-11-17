#!/bin/bash
cd ~/oot-bc250-tests
./routerun.sh castle2 castle2-ht30 v17-e4e80a8fa2 EDEN_NX2_HEAP_TRIM_S=30; sleep 10
./routerun.sh castle2 castle2-ht0 v17-e4e80a8fa2 ''
