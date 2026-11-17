#!/bin/bash
# t1run.sh <label> <bin> <env> [loops]: long run with the 1 s memory sampler and stutter trace, then t1stats summary.
L=$1; B=$2; E=$3; LOOPS=${4:-3}; cd ~/oot-bc250-tests
export XDG_RUNTIME_DIR=/run/user/1000
until ! pgrep -x eden-cli >/dev/null; do sleep 2; done
systemctl --user reset-failed t1w-$L 2>/dev/null
systemd-run --user --unit=t1w-$L --collect ~/oot-bc250-tests/t1watch.sh ${BC250_HOME:-$HOME}/oot-bc250-tests/t1-$L.txt >/dev/null
./longrun.sh $L $B "EDEN_NX2_STUTTER_TRACE=1${E:+;$E}" $LOOPS
python3 -I t1stats.py $L | awk 'NR<=2 || /pre/ || NR<=12'
python3 - "$L" <<'EOF'
import sys
L = sys.argv[1]
start = int(dict(l.split() for l in open(f"long-{L}.txt"))["start"])
s = [list(map(float, l.split())) for l in open(f"t1-{L}.txt") if len(l.split()) >= 11]
pre = [x for x in s if start - 50 <= x[0] <= start + 60]
if pre:
    print(f"  load+first minute: swapout {int(pre[-1][2]-pre[0][2])} pages, majflt {int(pre[-1][3]-pre[0][3])}, "
          f"min avail {int(min(x[6] for x in pre))} MB, peak gtt {int(max(x[8] for x in pre))} MB, "
          f"peak eden anon {int(max(x[9] for x in pre))} MB")
EOF
