#!/bin/bash
# gemloop.sh <label prefix> <first n> <last n> (root): gemwatch each new eden-cli launch in turn.
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
last=$(pgrep -x eden-cli)
for n in $(seq $2 $3); do
  while :; do p=$(pgrep -x eden-cli); [ -n "$p" ] && [ "$p" != "$last" ] && break; [ -z "$p" ] && last=; sleep 1; done
  last=$p; ./gemwatch.sh $1-$n
done
