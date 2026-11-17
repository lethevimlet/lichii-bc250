#!/bin/bash
# oot-horse.sh <label>: Hyrule Field on Epona (save set hyrule-horse-set). Gallop straight spurring with A, then gallop
# while spinning the camera (Epona circles: forward is camera-relative), both directions, twice. Worst case for fps:
# fast travel streams the field in while the view turns.
R=horse L=$1; . ~/oot-bc250-tests/oot-routelib.sh
load; mark start
for lap in 1 2; do
  ride 15 0;  mark gallop$lap
  ride 15 1;  mark circleR$lap
  ride 15 0;  mark gallopB$lap
  ride 15 -1; mark circleL$lap
done
echo "end $(up)" >> long-$L.txt
