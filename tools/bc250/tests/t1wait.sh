#!/bin/bash
# t1wait.sh <out>: wait (any time) for eden-cli, then run t1watch.sh.
until pgrep -x eden-cli >/dev/null; do sleep 5; done
exec /bin/bash ${BC250_HOME:-$HOME}/oot-bc250-tests/t1watch.sh "$1"
