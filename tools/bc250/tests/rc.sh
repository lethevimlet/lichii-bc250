#!/bin/bash
cd ~/oot-bc250-tests
./routerun.sh castle2 castle2-rc512 v17-e509871b7a "EDEN_NX2_IMAGE_RECYCLE_MIB=512"; sleep 10
./routerun.sh castle2 castle2-rc1024 v17-e509871b7a "EDEN_NX2_IMAGE_RECYCLE_MIB=1024"; sleep 10
./routerun.sh castle2 castle2-rc256 v17-e509871b7a ""
