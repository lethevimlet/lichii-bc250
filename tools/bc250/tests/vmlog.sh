#!/bin/bash
# vmlog.sh <out>: every 2 s while eden-cli runs: kernel reclaim/compaction/swap counters (cumulative).
out=$1
for i in $(seq 60); do pgrep -x eden-cli >/dev/null && break; sleep 3; done
while pgrep -x eden-cli >/dev/null; do
  echo "$(date +%T) $(grep -E "^(compact_stall|allocstall_movable|allocstall_normal|pswpin|pswpout|pgmajfault) " /proc/vmstat | tr "\n" " ")" >> "$out"
  sleep 2
done
