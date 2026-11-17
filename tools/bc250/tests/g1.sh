#!/bin/bash
cd ~/oot-bc250-tests
for r in kokiri horse castle2; do ./routerun.sh $r $r-g1 v17-e509871b7a ""; sleep 10; done
