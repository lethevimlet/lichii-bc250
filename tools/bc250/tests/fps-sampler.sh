#!/bin/bash
# fps-sampler.sh <out>: once a second while eden-cli runs: wall time, guest presents in that
# second, MemAvailable MB, swap used MB, GPU GTT used MB. For lining up drops with other logs.
out=$1; cd ~/oot-bc250-tests || exit 1
for i in $(seq 60); do pgrep -x eden-cli >/dev/null && break; sleep 3; done
prev=""
while pgrep -x eden-cli >/dev/null; do
  p=$(./dbg.sh '{"method":"status"}' 2>/dev/null | grep -oE '"presents": [0-9]+' | grep -oE '[0-9]+')
  m=$(awk '/MemAvailable/{a=$2} /SwapTotal/{t=$2} /SwapFree/{f=$2} END{printf "%d %d", a/1024, (t-f)/1024}' /proc/meminfo)
  g=$(( $(cat /sys/class/drm/card1/device/mem_info_gtt_used) >> 20 ))
  if [ -n "$p" ] && [ -n "$prev" ]; then echo "$(date +%T.%N | cut -c1-12) fps $((p - prev)) mem_avail $m gtt $g" >> "$out"; fi
  prev=$p
  sleep 1
done
