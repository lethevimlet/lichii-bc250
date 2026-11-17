#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
./bootmem.sh bmtc1 rel-v7 "GLIBC_TUNABLES=glibc.malloc.tcache_max=1032" 150
./bootmem.sh bmtc0 rel-v7 "GLIBC_TUNABLES=glibc.malloc.tcache_count=0" 150
