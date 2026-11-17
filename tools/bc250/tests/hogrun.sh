#!/bin/bash
# hogrun.sh <label> <bin> [hogGB]: castle route while a separate process holds <hogGB> of incompressible memory
# (from 100 s after the game appears until the route ends), simulating a long session's memory pressure.
L=$1; B=$2; G=${3:-4}; cd ~/oot-bc250-tests
until ! pgrep -x eden-cli >/dev/null; do sleep 2; done
( until pgrep -x eden-cli >/dev/null; do sleep 1; done; sleep 100
  exec systemd-run --user --collect --unit=hog-$L --wait -p MemoryMax=$((G+1))G /usr/bin/python3 -I -c "
import os,time
b=[bytearray(os.urandom(1<<26)) for _ in range($G*16)]
deadline=time.time()+900
while time.time()<deadline and not os.path.exists('/tmp/hog-stop-$L'): time.sleep(2)
" ) &
rm -f /tmp/hog-stop-$L
./castlerun.sh $L $B "" > $L.out 2>&1
touch /tmp/hog-stop-$L
python3 castlestats.py $L >> $L.out 2>&1
wait
echo "large-collector $(grep -c "Large image deleted (collector)" log-$L.txt)" >> $L.out
grep -o "[0-9]* recent GPU-written kept" log-$L.txt | awk '{s+=$1} END{print "kept", s+0}' >> $L.out
