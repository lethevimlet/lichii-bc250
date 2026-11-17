#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
./bootmem.sh bm26nf rel-v7 "DISABLE_VK_LAYER_VALVE_steam_fossilize_1=1" 150
./bootmem.sh bm25b exp/kept-pipelines-5da032dc3f "" 150
