#!/bin/bash
cd ~/oot-bc250-tests
N150=${BC250_HOME:-$HOME}/lichii-bc250-dev/build/bin/eden-cli
N130=${BC250_HOME:-$HOME}/Applications/eden-bins/l130-896264f38a/eden-cli
run() { BIN=$2 ./ab-run.sh $1 "$3" 2>&1 | grep -E "fps|samples" >> batch3.txt; }



run l130-c $N130 ""; run l150-c $N150 ""; run l130-d $N130 ""; run l150-d $N150 ""
rm -f vma-l150*.json*
run l150-vma $N150 "EDEN_NX2_VMA_DUMP=${BC250_HOME:-$HOME}/oot-bc250-tests/vma-l150.json;EDEN_NX2_TC_LOG=10"
cp ~/.local/share/eden/log/eden_log.txt log-l150-vma.txt
ls -la vma-l150* >> batch3.txt; echo DONE >> batch3.txt
