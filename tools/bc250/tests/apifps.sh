#!/bin/bash
# apifps.sh <label>: gamescope composited fps (via bc250-api) every 2 s from walk start to route end.
L=$1; cd ~/oot-bc250-tests; out=apifps-$L.txt; : > $out
until [ -f shot-$L-start.png ]; do pgrep -x eden-cli >/dev/null || sleep 1; sleep 1; done
until [ -f shot-$L-x.png ]; do curl -s http://127.0.0.1:8250/api/status | python3 -c "import sys,json; print(json.load(sys.stdin)[\"fps\"])" >> $out; sleep 2; done
