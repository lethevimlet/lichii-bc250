cd ${BC250_HOME:-$HOME}/oot-bc250-tests
./bootmem.sh bmrt rt-v7 "" 150
./castlerun.sh rtc1 rt-v7 "" > ${BC250_HOME:-$HOME}/oot-bc250-tests/rtc1.out 2>&1
python3 castlestats.py rtc1 >> ${BC250_HOME:-$HOME}/oot-bc250-tests/rtc1.out 2>&1
