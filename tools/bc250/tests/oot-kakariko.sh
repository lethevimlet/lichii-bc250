#!/bin/bash
# oot-kakariko.sh <label>: adult Kakariko (save set kakariko-set, start by the windmill path). Walk straight, then walk
# while turning the camera (Link curves: forward is camera-relative), both directions, twice.
R=kakariko L=$1; . ~/oot-bc250-tests/oot-routelib.sh
load; mark start
for lap in 1 2; do
  walk 0 1 10;   mark walk$lap
  walkspin 1 10; mark turnR$lap
  walk 0 1 8;    mark walkB$lap
  walkspin -1 10; mark turnL$lap
done
echo "end $(up)" >> long-$L.txt
