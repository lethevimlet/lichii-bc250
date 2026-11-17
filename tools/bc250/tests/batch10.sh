#!/bin/bash
cd ~/oot-bc250-tests
JT=${BC250_HOME:-$HOME}/Applications/eden-bins/jt-5f8f2ae3c4/eden-cli
PGO=${BC250_HOME:-$HOME}/Applications/eden-bins/pgo-5f8f2ae3c4/eden-cli
for r in a b c; do
  BIN6=$PGO ./batch6.sh pgo$r "" 1
  BIN6=$JT ./batch6.sh nopgo$r "" 1
done
