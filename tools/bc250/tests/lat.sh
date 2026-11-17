#!/bin/bash
# lat.sh: input-lag A/B on the Kokiri route (frame gen off/on, FIFO/mailbox, gamescope 30 fps cap).
cd ~/oot-bc250-tests
B=v16-1b370d0a94
NOFG="pin_gpu_threads=true;frame_gen_target_rate=0;frame_gen_queue_target=1;frame_gen=false"
uncap() { DISPLAY=:0 xprop -root -remove GAMESCOPE_FPS_LIMIT 2>/dev/null; }
trap uncap EXIT
capafter() { # cap to 30 once the route starts (Steam sets the atom the same way)
  ( until grep -q "^start " long-$1.txt 2>/dev/null; do sleep 1; done
    DISPLAY=:0 xprop -root -f GAMESCOPE_FPS_LIMIT 32c -set GAMESCOPE_FPS_LIMIT 30; echo "cap set $1" ) & }
run() { L=$1 E=$2 I=$3 C=$4; rm -f long-$L.txt; uncap; [ "$C" = cap ] && capafter $L
  INI="$I" ./routerun.sh kokiri $L $B "EDEN_NX2_PRESENT_LATENCY_LOG=1;$E"; uncap; sleep 10; }
run lat-fifo     ""                            "$NOFG" nocap
run lat-fifocap  ""                            "$NOFG" cap
run lat-mboxcap  "EDEN_NX2_NOFG_PRESENT=mailbox" "$NOFG" cap
run lat-mbox     "EDEN_NX2_NOFG_PRESENT=mailbox" "$NOFG" nocap
run lat-fg       ""                            "pin_gpu_threads=true;frame_gen_target_rate=0;frame_gen_queue_target=1" nocap
