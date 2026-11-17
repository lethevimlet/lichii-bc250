#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
X=exp/kept-pipelines-5da032dc3f
./bootmem.sh bm25p0 $X "EDEN_NX2_PRELOAD_ALL_PIPELINES=0" 300
./bootmem.sh bm25p1 $X "EDEN_NX2_PRELOAD_ALL_PIPELINES=1" 480
./bootmem.sh bm26p0 rel-v7 "EDEN_NX2_PRELOAD_ALL_PIPELINES=0" 300
./bootmem.sh bm26p1 rel-v7 "EDEN_NX2_PRELOAD_ALL_PIPELINES=1" 480
