#!/bin/bash
# fg60.sh: A/B frame_gen_target_rate 30 vs 60 on route 2 (fg-080b0f3a5f build)
cd ~/oot-bc250-tests
export BIN6=${BC250_HOME:-$HOME}/Applications/eden-bins/fg-080b0f3a5f/eden-cli EXTRA=1
echo "=== fg60 batch $(date)" >> batch6.txt
for r in 1 2 3; do
  INI="pin_gpu_threads=true" ./batch6.sh fg30r$r "" 1
  INI="pin_gpu_threads=true;frame_gen_target_rate=60" ./batch6.sh fg60r$r "" 1
done
for f in log-fg*-1.txt; do echo "$f"; grep "Frame gen output" $f | tail -20; done > fg60-output.txt
