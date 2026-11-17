#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
B=v14-aaba473404
for p in "kpd1|" "kp3a|EDEN_NX2_KEPT_PIPELINES=3000" "kpd2|" "kp3b|EDEN_NX2_KEPT_PIPELINES=3000"; do
  L=${p%%|*}; E=${p#*|}
  ./bootmem.sh $L $B "$E" 150 > $L.out 2>&1
  grep -h "Background prebuild done\|boot load:" log-$L.txt | sed "s/.*TickFrame: //;s/.*LoadPipelinesV2: //" | cut -c1-200 >> $L.out
done
echo done > kpseq.done
