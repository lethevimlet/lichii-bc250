# gpubusy.py [seconds]: GPU gfx/compute busy % of eden-cli (and gamescope) from DRM fdinfo
import pathlib, subprocess, sys, time
def engines(pid):
    tot = {}
    seen = set()
    for fd in pathlib.Path(f'/proc/{pid}/fdinfo').iterdir():
        try:
            txt = fd.read_text()
        except OSError:
            continue
        if 'drm-client-id' not in txt:
            continue
        cid = [l for l in txt.splitlines() if l.startswith('drm-client-id')][0]
        if cid in seen:
            continue
        seen.add(cid)
        for l in txt.splitlines():
            if l.startswith('drm-engine-') and l.endswith(' ns'):
                k, v = l.split(':', 1)
                tot[k[11:]] = tot.get(k[11:], 0) + int(v.split()[0])
    return tot
secs = float(sys.argv[1]) if len(sys.argv) > 1 else 10
pids = {n: int(subprocess.check_output(['pgrep', '-x', n], text=True).split()[0]) for n in ("eden-cli",)}
a = {n: engines(p) for n, p in pids.items()}
time.sleep(secs)
b = {n: engines(p) for n, p in pids.items()}
for n in pids:
    print(n, '  '.join(f'{k} {(b[n][k] - a[n].get(k, 0)) / secs / 1e7:.0f}%' for k in b[n] if b[n][k] - a[n].get(k, 0) > 0))
