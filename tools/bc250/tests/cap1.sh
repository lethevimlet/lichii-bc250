#!/bin/bash
cd ~/oot-bc250-tests
WSI="VK_ADD_IMPLICIT_LAYER_PATH=${BC250_HOME:-$HOME}/oot-bc250-tests/gswsi;ENABLE_GAMESCOPE_WSI=1;LD_PRELOAD=${BC250_HOME:-$HOME}/oot-bc250-tests/gswsi/libstdc++.so.6"
INI="pin_gpu_threads=true;frame_gen_target_rate=0;frame_gen_queue_target=1;frame_gen=false" IDLE=900 \
  ./routerun.sh idle $1 ${2:-v16-1b370d0a94} "EDEN_NX2_PRESENT_LATENCY_LOG=1;$WSI;$3"
