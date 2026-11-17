#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
./bootmem.sh bmje rel-v7 "LD_PRELOAD=${BC250_HOME:-$HOME}/alloc/libjemalloc.so.2" 150
./bootmem.sh bmmi rel-v7 "LD_PRELOAD=${BC250_HOME:-$HOME}/alloc/libmimalloc.so.2" 150
