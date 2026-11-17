#!/bin/bash
# kx.sh (root): castle2 A/B: baseline, vm.extfrag_threshold=1000, EDEN_NX2_MEM_RESERVE_MIB=256. Writes kx.done.
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
ORIG=$(cat /proc/sys/vm/extfrag_threshold)
restore() { sysctl -qw vm.extfrag_threshold=$ORIG; }
trap restore EXIT
U() { runuser -u "${BC250_USER:-$USER}" -- env HOME=${BC250_HOME:-$HOME} XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus "$@"; }
run() { L=$1 E=$2; echo "== $L $(date +%T)" >> reclaimhelper.log
  U systemd-run --user --collect --unit=rh-$L /bin/bash ${BC250_HOME:-$HOME}/oot-bc250-tests/reclaimhelper.sh >/dev/null
  U bash ./withtest.sh ./routerun.sh castle2 $L v17-4fbde27eb7 "$E"; sleep 10; }
rm -f kx.done
run castle2-kb1 ""
sysctl -qw vm.extfrag_threshold=1000
run castle2-ke1 ""; run castle2-ke2 ""
restore
run castle2-kr1 "EDEN_NX2_MEM_RESERVE_MIB=256"; run castle2-kr2 "EDEN_NX2_MEM_RESERVE_MIB=256"
run castle2-kb2 ""
date > kx.done; chown "${BC250_USER:-$USER}:" kx.done
