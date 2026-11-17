#!/bin/bash
cd ~/oot-bc250-tests
for r in a b; do
  ./batch6.sh base$r "" 1
  ./batch6.sh tc$r "EDEN_NX2_TC_EXPECTED_MIB=2560;EDEN_NX2_TC_CRITICAL_MIB=3072" 1
done
