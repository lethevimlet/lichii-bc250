#!/bin/bash
# allroutes.sh <bin> <suffix> [env]: horse, kakariko, kokiri, castle2 back to back; labels <route>-<suffix>.
B=$1 S=$2 E=$3; cd ~/oot-bc250-tests
for r in horse kakariko kokiri castle2; do
  echo "=== $r-$S"; ./routerun.sh $r $r-$S $B "$E"; sleep 10
done
