#!/bin/bash
# zwb.sh setup|teardown|status|daemon (root): zram with an NVMe backing file for incompressible pages.
# Runtime only: a reboot restores the stock zram from zram-generator.
set -u
Z=/sys/block/zram0; IMG=/var/swap/zram-wb.img; STATE=/run/zwb-loop
size() { awk '{print $1}' /proc/swaps >/dev/null; cat $Z/disksize; }
case "${1:-}" in
setup)
  pgrep -x eden-cli >/dev/null && { echo "game running"; exit 1; }
  DS=$(cat $Z/disksize)
  [ -f $IMG ] || { fallocate -l 4G $IMG && chmod 600 $IMG; }
  LOOP=$(losetup --find --show --direct-io=on $IMG) || exit 1
  echo $LOOP > $STATE
  swapoff /dev/zram0 || exit 1
  echo 1 > $Z/reset
  echo $LOOP > $Z/backing_dev
  echo zstd > $Z/comp_algorithm
  echo $DS > $Z/disksize
  mkswap /dev/zram0 >/dev/null && swapon -p 100 /dev/zram0
  echo "zram0 backing $(cat $Z/backing_dev) disksize $(cat $Z/disksize)"; swapon --show ;;
teardown)
  pgrep -x eden-cli >/dev/null && { echo "game running"; exit 1; }
  DS=$(cat $Z/disksize)
  swapoff /dev/zram0 || exit 1
  echo 1 > $Z/reset
  echo zstd > $Z/comp_algorithm
  echo $DS > $Z/disksize
  mkswap /dev/zram0 >/dev/null && swapon -p 100 /dev/zram0
  [ -f $STATE ] && losetup -d $(cat $STATE) && rm -f $STATE
  echo "zram0 backing $(cat $Z/backing_dev)"; swapon --show ;;
daemon)
  # write incompressible pages to the backing file every ${2:-2} s while the game runs
  while true; do
    if pgrep -x eden-cli >/dev/null; then echo huge > $Z/writeback 2>/dev/null; fi
    sleep ${2:-2}
  done ;;
status) echo "backing $(cat $Z/backing_dev)"; cat $Z/mm_stat; cat $Z/bd_stat; swapon --show ;;
esac
