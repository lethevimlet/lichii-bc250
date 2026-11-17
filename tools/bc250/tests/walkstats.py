# walkstats.py <label>: kernel counter deltas and slow frames per window (needs STUTTER_TRACE).
# Windows: walk (walk start..end) and, with route 2 (EXTRA=1), route2 (walk end..route end).
import sys, re
L = sys.argv[1]
blocks = open(f'vm-{L}.txt').read().split('== ')[1:]
up = [int(b.split('uptime')[1].split()[0]) for b in blocks]
d = [dict((l.split()[0], int(l.split()[1])) for l in b.strip().splitlines()[1:]) for b in blocks]
def window(a, b, name):
    w = {k: d[b][k] - d[a][k] for k in d[a]}
    over50 = over100 = 0; worst = 0.0
    for l in open(f'log-{L}.txt', errors='replace'):
        if 'Nx2Stutter frame=' not in l: continue
        t = float(l.split(']')[0].strip('[ '))
        if up[a] <= t <= up[b] + 1:
            ms = float(re.search(r'ms=([\d.]+)', l).group(1))
            over50 += ms > 50; over100 += ms > 100; worst = max(worst, ms)
    print(f'  {L} {name}: frames>50ms {over50} >100ms {over100} worst {worst:.0f}ms | swpin {w["pswpin"]} swpout {w["pswpout"]} majflt {w["pgmajfault"]} compact {w["compact_stall"]}')
window(1, 2, 'walk')
if len(d) > 3: window(2, 3, 'route2')
