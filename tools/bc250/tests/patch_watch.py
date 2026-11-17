import sys
p = sys.argv[1]
s = open(p).read()
a = s.index("    if os.getenv('BC250_TEST_NOFG') == '1':")
b = s.index("    launcher.write_bytes(modified)")
new = r"""    import re
    text = (pathlib.Path.home() / 'Applications/sharkiix-mesh3.ini').read_text()
    if os.getenv('BC250_TEST_NOFG') == '1':
        assert text.count('\nframe_gen=true\n') == 1
        text = text.replace('\nframe_gen=true\n', '\nframe_gen=false\n')
    edits = list(filter(None, os.getenv('BC250_TEST_INI', '').split(';')))
    resolution = os.getenv('BC250_TEST_RES')
    if resolution:
        edits.append('resolution_setup=' + resolution)
    for line in edits:
        key = line.split('=')[0]
        text, n = re.subn(r'\n' + re.escape(key) + r'=[^\n]*\n', lambda m: '\n' + line + '\n', text)
        assert n == 1, key
        text = text.replace('\n' + key + '\\default=true\n', '\n' + key + '\\default=false\n')
    config = pathlib.Path('/tmp/bc250-test.ini')
    config.write_text(text)
    assert modified.count(b'$APP/sharkiix-mesh3.ini') == 1
    modified = modified.replace(b'$APP/sharkiix-mesh3.ini', b'/tmp/bc250-test.ini')
    for line in filter(None, os.getenv('BC250_TEST_ENV', '').split(';')):
        modified = modified.replace(marker, marker + ('    export ' + line + '\n').encode())
"""
s = s[:a] + new + s[b:]
open(p, 'w').write(s)
