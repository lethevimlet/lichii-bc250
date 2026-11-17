#!/bin/bash
# memwatch.sh <out>: every 2 s while eden-cli runs: MemAvailable, AnonPages, Shmem, Cached, swap used,
# zram data, GTT, eden-cli RSS anon/file/shmem and swapped (MB).
out=$1
for i in $(seq 60); do pgrep -x eden-cli >/dev/null && break; sleep 3; done
while P=$(pgrep -x eden-cli); do
  m=$(awk '/^(MemAvailable|AnonPages|Shmem|Cached|SwapTotal|SwapFree|Unevictable|Mlocked):/{v[$1]=int($2/1024)} END{printf "avail %d anon %d shmem %d cached %d swap %d unevict %d", v["MemAvailable:"], v["AnonPages:"], v["Shmem:"], v["Cached:"], v["SwapTotal:"]-v["SwapFree:"], v["Unevictable:"]}' /proc/meminfo)
  z=$(awk '{printf "%d", $1/1048576}' /sys/block/zram0/mm_stat 2>/dev/null)
  r=$(awk '/^(RssAnon|RssFile|RssShmem|VmSwap):/{printf "%s %d ", $1, $2/1024}' /proc/$P/status)
  g=$(( $(cat /sys/class/drm/card1/device/mem_info_gtt_used) >> 20 ))
  echo "$(date +%T) $m zram $z gtt $g eden $r" >> "$out"
  sleep 2
done
