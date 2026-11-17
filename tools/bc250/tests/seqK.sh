#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
./bootmem.sh bm26nc rel-v7 "MESA_SHADER_CACHE_DISABLE=true" 150
./bootmem.sh bm26rn rel-v7 "RADV_DEBUG=nocache" 150
./bootmem.sh bm26b rel-v7 "" 150
