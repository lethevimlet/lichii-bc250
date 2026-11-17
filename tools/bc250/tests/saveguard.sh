#!/bin/bash
# saveguard.sh test|restore: make test runs start from the same Ocarina save without touching the owner's.
#   test     back the live save folder up to ~/save-backups/live-during-test.tgz (only if no test copy is in
#            place already) and put the frozen test set (~/save-backups/test-set.tgz) in its place
#   restore  put the live save folder back from that backup
# The test set: the owner's saves of 2026-11-12 03:26 with slot_03 (the newest, an autosave a test walk made)
# replaced by slot_04 (the owner's Hyrule Field spot facing the ranch), so "Continue" loads that spot.
set -euo pipefail
BASE=~/.local/share/eden/nand/user/save/0000000000000000/54ABF3265C9563F764085CDC43612819
DIR=0400486024DEC000
B=~/save-backups
MARK=$B/test-set-in-place
case "${1:-}" in
  test)
    pgrep -x eden-cli >/dev/null && { echo "saveguard: game running, not touching saves" >&2; exit 1; }
    if [ ! -e "$MARK" ]; then
      tar -C "$BASE" -czf "$B/live-during-test.tgz" "$DIR"
      touch "$MARK"
    fi
    rm -rf "${BASE:?}/$DIR"
    tar -C "$BASE" -xzf "$B/${SAVE_SET:-test-set}.tgz"
    ;;
  restore)
    pgrep -x eden-cli >/dev/null && { echo "saveguard: game running, not touching saves" >&2; exit 1; }
    [ -e "$MARK" ] || exit 0
    rm -rf "${BASE:?}/$DIR"
    tar -C "$BASE" -xzf "$B/live-during-test.tgz"
    rm -f "$MARK"
    ;;
  *) echo "usage: saveguard.sh test|restore" >&2; exit 1 ;;
esac
