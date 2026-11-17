#!/bin/bash
cd ~/oot-bc250-tests
./batch6.sh lz4
./batch6.sh tc25 "EDEN_NX2_TC_EXPECTED_MIB=2560;EDEN_NX2_TC_CRITICAL_MIB=3072"
