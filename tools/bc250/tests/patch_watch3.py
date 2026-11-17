import os
import sys
p = sys.argv[1]; s = open(p).read()
anchor = "    launcher.write_bytes(modified)\n"
add = """    test_bin = os.getenv('BC250_TEST_BIN')
    if test_bin:
        old_bin = os.path.expanduser('~/oot-bc250/build/bin/eden-cli').encode()
        assert modified.count(old_bin) == 1 and pathlib.Path(test_bin).is_file()
        modified = modified.replace(old_bin, test_bin.encode())
"""
assert s.count(anchor) == 1 and 'BC250_TEST_BIN' not in s
s = s.replace(anchor, add + anchor)
open(p, 'w').write(s)
