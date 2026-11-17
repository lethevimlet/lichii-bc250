#!/bin/bash
cd ~/oot-bc250-tests
REF=${BC250_HOME:-$HOME}/Applications/eden-bins/main-02fff43027/eden-cli
NEW=${BC250_HOME:-$HOME}/Applications/eden-bins/jt-5f8f2ae3c4/eden-cli
for r in d e f; do
  BIN6=$REF ./batch6.sh ref$r "" 1
  BIN6=$NEW ./batch6.sh jt$r "" 1
done
