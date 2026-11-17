#!/bin/bash
# gemwatch.sh <label> (root): while eden-cli runs, sample GTT every second; on each new GTT high
# save the amdgpu_gem_info summary to gem-<label>-peak.txt; log "time gtt_mib" to gem-<label>.log.
cd ${BC250_HOME:-$HOME}/oot-bc250-tests; L=$1; max=0
for i in $(seq 120); do pgrep -x eden-cli >/dev/null && break; sleep 1; done
while pgrep -x eden-cli >/dev/null; do
  g=$(( $(cat /sys/class/drm/card1/device/mem_info_gtt_used) >> 20 ))
  echo "$(date +%T) $g" >> gem-$L.log
  if [ $g -gt $((max + 64)) ]; then
    max=$g; { echo "== $(date +%T) gtt $g MiB"; python3 -I gemsum.py < /sys/kernel/debug/dri/1/amdgpu_gem_info; } > gem-$L-peak.tmp && mv gem-$L-peak.tmp gem-$L-peak.txt
  fi
  sleep 1
done
chown "${BC250_USER:-$USER}:" gem-$L*
