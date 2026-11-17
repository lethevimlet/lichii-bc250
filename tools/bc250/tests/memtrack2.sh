#!/bin/bash
# memtrack2.sh <label> [interval]: waits for eden-cli, then every <interval> s (default 120) saves the smaps summary plus a
# compact per-mapping list of private memory (start size perms rss swap name; guest memfd skipped) stamped with the
# emulator's uptime, so mappings can be diffed between snapshots. Exits when the game exits. Run as root.
L=$1; IV=${2:-120}; cd ${BC250_HOME:-$HOME}/oot-bc250-tests
sum=memtrack-$L.txt; maps=memmaps-$L.txt; : > $sum; : > $maps
until P=$(pgrep -x eden-cli | tail -1) && [ -n "$P" ]; do sleep 5; done
HZ=$(getconf CLK_TCK); start=$(awk -v hz=$HZ '{print $22/hz}' /proc/$P/stat)
while [ -d /proc/$P ]; do
  up=$(awk -v s=$start '{printf "%d", $1-s}' /proc/uptime)
  if cp /proc/$P/smaps /tmp/smaps-$L 2>/dev/null; then
    { echo "== t=$up pid=$P"; grep -E "RssAnon|VmSwap" /proc/$P/status | tr -s " " | tr "\n" " "; echo; python3 -I smapsum.py /tmp/smaps-$L; } >> $sum 2>&1
    { echo "== t=$up"; awk '/^[0-9a-f]+-[0-9a-f]+ /{split($1,a,"-"); n=$6; s=a[1]; sz=(strtonum("0x" a[2])-strtonum("0x" a[1]))/1024; p=$2; r=0; next}
      /^Rss:/{r=$2} /^Swap:/{ if (n !~ /^\/memfd:HostMemory/ && (r+$2)>=256) print s, sz, p, r, $2, n }' /tmp/smaps-$L; } >> $maps
  fi
  for i in $(seq $IV); do [ -d /proc/$P ] || break; sleep 1; done
done
rm -f /tmp/smaps-$L
