#!/bin/bash
# v19p.sh (root): castle2 run on v19 with GPU profile + stutter trace, DWARF perf of GPUBack for 12 s from centre1.
T=${BC250_HOME:-$HOME}/oot-bc250-tests; cd $T; rm -f v19p.done
U() { runuser -u "${BC250_USER:-$USER}" -- env HOME=${BC250_HOME:-$HOME} XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus "$@"; }
L=castle2-sp1
rm -f long-$L.txt
bash $T/perfdwarf.sh $L centre1 12 &
U systemd-run --user --collect --unit=rh-sp1 /bin/bash $T/reclaimhelper.sh >/dev/null
U bash ./withtest.sh ./routerun.sh castle2 $L v19-e887c4b570 "EDEN_NX2_GPU_PROFILE=1;EDEN_NX2_STUTTER_TRACE=1"
wait
date > v19p.done; chown "${BC250_USER:-$USER}:" v19p.done
