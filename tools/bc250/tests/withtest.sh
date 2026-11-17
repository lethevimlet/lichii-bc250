#!/bin/bash
# withtest.sh <cmd...>: run a test with the harness launcher (Eglantine.pre-v8-release), then put the normal launcher back.
# The owner's launcher is saved only when Eglantine is not the harness copy (a test stopped with systemctl stop
# once left the harness in place, and the next test saved that as the owner's). The restore runs on TERM/INT too.
A=${BC250_HOME:-$HOME}/Applications
if cmp -s $A/Eglantine $A/Eglantine.pre-v8-release; then
  echo "withtest: Eglantine is already the harness launcher; keeping Eglantine.owner-saved" >&2
  cmp -s $A/Eglantine.owner-saved $A/Eglantine.pre-v8-release && { echo "withtest: no owner launcher saved, refusing" >&2; exit 1; }
else
  cp -p $A/Eglantine $A/Eglantine.owner-saved
fi
cp -p $A/Eglantine.pre-v8-release $A/Eglantine
restore() { cp -p $A/Eglantine.owner-saved $A/Eglantine; }
trap restore EXIT
trap 'restore; trap - EXIT; kill -- -$$ 2>/dev/null; exit 143' TERM INT
"$@"
