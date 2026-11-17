#!/bin/bash
cd ~/oot-bc250-tests
export BIN6=${BC250_HOME:-$HOME}/Applications/eden-bins/fg-080b0f3a5f/eden-cli EXTRA=1
echo "=== fg0 batch $(date)" >> batch6.txt
for r in 1 2 3; do
  INI="pin_gpu_threads=true;frame_gen_target_rate=0" ./batch6.sh fg0r$r "" 1
done
