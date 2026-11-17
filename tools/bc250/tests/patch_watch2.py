import sys
p = sys.argv[1]; s = open(p).read()
guard = """for _p in pathlib.Path('/proc').iterdir():
    try:
        if _p.name.isdigit() and b'AppId=3688079378' in (_p / 'cmdline').read_bytes() and (_p / 'comm').read_text().strip() == 'reaper':
            raise SystemExit('a previous Steam launch of the shortcut is still alive: clean it up first')
    except (FileNotFoundError, ProcessLookupError, PermissionError):
        pass
subprocess.run(['podman', 'start', 'bc250-meshbuild'], stdout=subprocess.DEVNULL, check=True)
"""
anchor = "started = time.monotonic()\n"
assert s.count(anchor) == 1 and 'previous Steam launch' not in s
s = s.replace(anchor, guard + anchor)
open(p, 'w').write(s)
