#!/bin/bash
cd ${BC250_HOME:-$HOME}/oot-bc250-tests
./bootmem.sh bm25nat rel-v7 "LD_LIBRARY_PATH=${BC250_HOME:-$HOME}/mesa25/lib;VK_ICD_FILENAMES=${BC250_HOME:-$HOME}/mesa25/icd.json" 150
