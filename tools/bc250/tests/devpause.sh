#!/bin/bash
# devpause.sh pause|resume|status: let the owner play the v18 shortcut in the middle of dev work.
#   pause   PAUSED flag (routerun.sh waits, v5build refuses), stop test/build user units, kill a test game,
#           put the owner's launcher and saves back, show the state
#   resume  remove the flag (waiting batches continue)
T=~/oot-bc250-tests A=~/Applications
export XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
case "${1:-status}" in
pause)
  touch $T/PAUSED
  units=$(systemctl --user list-units --no-legend --plain 'oot-*' 'tlx*' 'seq*' 'rh-*' 't1w-*' 'build-v5*' 'v19-*' | awk '{print $1}')
  testgame=0; [ -n "$(systemctl --user list-units --no-legend 'oot-*')" ] && testgame=1
  cmp -s $A/Eglantine $A/Eglantine.pre-v8-release && testgame=1
  [ -n "$units" ] && systemctl --user stop $units
  if [ $testgame = 1 ] && pgrep -x eden-cli >/dev/null; then pkill -x eden-cli; for i in $(seq 30); do pgrep -x eden-cli >/dev/null || break; sleep 1; done; fi
  cmp -s $A/Eglantine $A/Eglantine.pre-v8-release && cp -p $A/Eglantine.owner-saved $A/Eglantine
  pgrep -x eden-cli >/dev/null || $T/saveguard.sh restore
  ;;
resume) rm -f $T/PAUSED ;;
esac
echo "paused: $([ -e $T/PAUSED ] && echo yes || echo no)"
echo "launcher: $(grep -o 'lichii-bc250/lichii-bc250-v[0-9a-z]*' $A/Eglantine | head -1)"
echo "test saves in place: $([ -e ~/save-backups/test-set-in-place ] && echo YES || echo no)"
echo "game running: $(pgrep -x eden-cli >/dev/null && echo yes || echo no)"
echo "units: $(systemctl --user list-units --no-legend --plain 'oot-*' 'tlx*' 'build-v5*' 'v19-*' | awk '{print $1}' | tr '\n' ' ')"
