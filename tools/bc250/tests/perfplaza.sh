#!/bin/bash
# perfplaza.sh <label> <mark> <secs> (root): when long-<label>.txt reaches <mark>, record the GPU threads (GPUBack,
# GPU front) and the whole process with perf for <secs> seconds (perf from the bc250-meshbuild container, the
# kernel's perf_event_paranoid lowered to -1 for the recording only), then write per-thread symbol tables.
L=$1 M=$2 S=${3:-14}; T=${BC250_HOME:-$HOME}/oot-bc250-tests; O=$T/perf-$L
mkdir -p $O; chown "${BC250_USER:-$USER}:" $O
until grep -q "^$M [0-9]" $T/long-$L.txt 2>/dev/null; do sleep 0.5; done
P=$(pgrep -x eden-cli) || exit 1
back=""; front=""
for t in /proc/$P/task/*; do c=$(cat $t/comm); [ "$c" = GPUBack ] && back=${t##*/}; [ "$c" = GPU ] && front=${t##*/}; done
old=$(cat /proc/sys/kernel/perf_event_paranoid); echo -1 > /proc/sys/kernel/perf_event_paranoid
echo "pid $P back $back front $front" > $O/info.txt
runuser -u "${BC250_USER:-$USER}" -- env XDG_RUNTIME_DIR=/run/user/1000 distrobox enter bc250-meshbuild -- perf record -F 1999 -g -p $P -o /tmp/perf-$L.data -- sleep $S > $O/record.log 2>&1
echo $old > /proc/sys/kernel/perf_event_paranoid
for th in back front; do tid=${!th}; [ -n "$tid" ] || continue
  runuser -u "${BC250_USER:-$USER}" -- env XDG_RUNTIME_DIR=/run/user/1000 distrobox enter bc250-meshbuild -- perf report -i /tmp/perf-$L.data --tid $tid --no-children --sort symbol --stdio --percent-limit 0.4 -g none 2>/dev/null | grep -v "^#" | grep -v "^$" | head -70 > $O/$th-self.txt
  runuser -u "${BC250_USER:-$USER}" -- env XDG_RUNTIME_DIR=/run/user/1000 distrobox enter bc250-meshbuild -- perf report -i /tmp/perf-$L.data --tid $tid --children --sort symbol --stdio --percent-limit 2 -g none 2>/dev/null | grep -v "^#" | grep -v "^$" | head -70 > $O/$th-children.txt
done
runuser -u "${BC250_USER:-$USER}" -- env XDG_RUNTIME_DIR=/run/user/1000 distrobox enter bc250-meshbuild -- perf report -i /tmp/perf-$L.data --no-children --sort comm --stdio -g none 2>/dev/null | grep -v "^#" | grep -v "^$" | head -30 > $O/threads.txt
chown -R "${BC250_USER:-$USER}:" $O; echo done >> $O/info.txt
