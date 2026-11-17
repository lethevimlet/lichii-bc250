#!/bin/bash
# memacct.sh <label> [after-mark] [delay-s] (root): when long-<label>.txt reaches <after-mark> (default town1), wait <delay-s>
# (default 15) and write a full memory accounting to memacct-<label>.txt: meminfo, zram, eden-cli status + smaps by kind,
# guest RAM memfd resident/zero pages, amdgpu GEM buffers by process, top processes by RSS.
L=$1; M=${2:-town1}; W=${3:-15}; T=${BC250_HOME:-$HOME}/oot-bc250-tests; O=$T/memacct-$L.txt
for i in $(seq 900); do grep -q "^$M [0-9]" $T/long-$L.txt 2>/dev/null && break; sleep 1; done
sleep $W
P=$(pgrep -x eden-cli) || { echo "no eden-cli" > $O; exit 1; }
{
echo "== $(date +%T) label $L, $W s after $M, eden pid $P, uptime $(ps -o etimes= -p $P)"
echo "== meminfo"; grep -E "^(MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapCached|Active\(anon\)|Inactive\(anon\)|Active\(file\)|Inactive\(file\)|Unevictable|Shmem|AnonPages|Mapped|KReclaimable|Slab|SUnreclaim|KernelStack|PageTables|VmallocUsed|SwapTotal|SwapFree):" /proc/meminfo
echo "== gtt $(( $(cat /sys/class/drm/card1/device/mem_info_gtt_used) >> 20 )) MiB, vram $(( $(cat /sys/class/drm/card1/device/mem_info_vram_used) >> 20 )) MiB"
echo "== zram mm_stat (orig compr mem_used limit max same huge ...)"; awk '{printf "orig %d MiB, compressed %d MiB, RAM used %d MiB, same-filled pages %d\n", $1/1048576, $2/1048576, $3/1048576, $6}' /sys/block/zram0/mm_stat
swapon --show
echo "== eden status"; grep -E "^(VmRSS|RssAnon|RssFile|RssShmem|VmSwap|VmData|Threads):" /proc/$P/status
echo "== eden smaps by kind"; cat /proc/$P/smaps > /tmp/memacct-smaps; python3 -I $T/smapsum.py /tmp/memacct-smaps; rm -f /tmp/memacct-smaps
echo "== guest memory (memfd HostMemory)"; timeout 120 python3 -I $T/zeroscan.py $P
echo "== amdgpu GEM by process"; python3 -I $T/gemsum.py < /sys/kernel/debug/dri/1/amdgpu_gem_info 2>&1 | head -40
echo "== top RSS"; ps -eo rss,comm --sort=-rss | head -12
} > $O 2>&1
