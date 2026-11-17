#!/bin/bash
cd ~/oot-bc250-tests
./routerun.sh horse horse-tr1 v16-8eaac8305a "EDEN_NX2_TC_TRACE=1"; sleep 10
./routerun.sh horse horse-big1 v16-8eaac8305a "EDEN_NX2_TC_TRACE=1;EDEN_NX2_TC_EXPECTED_MIB=3072;EDEN_NX2_TC_CRITICAL_MIB=3584"
