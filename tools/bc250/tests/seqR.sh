cd ${BC250_HOME:-$HOME}/oot-bc250-tests
./castlerun.sh jit1 exp/kept-pipelines-5da032dc3f "" > ${BC250_HOME:-$HOME}/oot-bc250-tests/jit1.out 2>&1
python3 castlestats.py jit1 >> ${BC250_HOME:-$HOME}/oot-bc250-tests/jit1.out 2>&1
