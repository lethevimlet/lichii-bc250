#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
./bootmem.sh bmldr rel-v7 "LD_LIBRARY_PATH=${BC250_HOME:-$HOME}/ctrlibs/loader" 150
./bootmem.sh bmcxx rel-v7 "LD_LIBRARY_PATH=${BC250_HOME:-$HOME}/ctrlibs/cxx" 150
