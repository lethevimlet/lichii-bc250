#!/bin/bash
# t1watch.sh <out>: every second while eden-cli runs, stamped with the emulator's uptime (= its log time):
# cumulative pswpin pswpout pgmajfault allocstall(normal+movable) compact_stall, MemAvailable MB, swap used MB,
# GTT MB, eden-cli RSS anon MB and swapped MB.
out=$1; : > "$out"
for i in $(seq 60); do pgrep -x eden-cli >/dev/null && break; sleep 3; done
P=$(pgrep -x eden-cli); HZ=$(getconf CLK_TCK)
start=$(awk -v hz=$HZ '{print $22/hz}' /proc/$P/stat)
while [ -d /proc/$P ]; do
  up=$(awk -v s=$start '{printf "%.1f", $1-s}' /proc/uptime)
  v=$(awk '/^(pswpin|pswpout|pgmajfault|allocstall_normal|allocstall_movable|compact_stall) /{a[$1]=$2} END{printf "%d %d %d %d %d", a["pswpin"], a["pswpout"], a["pgmajfault"], a["allocstall_normal"]+a["allocstall_movable"], a["compact_stall"]}' /proc/vmstat)
  m=$(awk '/^(MemAvailable|SwapTotal|SwapFree):/{x[$1]=int($2/1024)} END{printf "%d %d", x["MemAvailable:"], x["SwapTotal:"]-x["SwapFree:"]}' /proc/meminfo)
  g=$(( $(cat /sys/class/drm/card1/device/mem_info_gtt_used) >> 20 ))
  r=$(awk '/^(RssAnon|VmSwap):/{printf "%d ", $2/1024}' /proc/$P/status 2>/dev/null)
  echo "$up $v $m $g $r" >> "$out"
  sleep 1
done
