# playstats.py <t1 sampler file> [since_uptime]: live view of a play session. For each 10 s
# "Screen:" window in the running log: screen fps, repeated frames, game fps and the memory
# activity in the same window (swap-ins/outs, major faults, MemAvailable, GTT).
import re
import sys
from pathlib import Path

samples = [list(map(float, l.split())) for l in open(sys.argv[1]) if len(l.split()) >= 11]
since = float(sys.argv[2]) if len(sys.argv) > 2 else 0.0
log = Path.home() / ".local/share/eden/log/eden_log.txt"
game = {}
rows = []
for line in open(log, errors="replace"):
    try:
        t = float(line.split("]")[0].strip("[ "))
    except ValueError:
        continue
    if m := re.search(r"Frame gen output: ([\d.]+) game fps", line):
        game[round(t)] = float(m.group(1))
    elif m := re.search(r"Screen: ([\d.]+) presents/s, (\d+) repeated frames.*?(\d+) gaps > 40 ms, "
                        r"worst gap ([\d.]+) ms", line):
        rows.append((t, float(m.group(1)), int(m.group(2)), int(m.group(3)), float(m.group(4))))


def window(a, b):
    s = [x for x in samples if a <= x[0] <= b]
    if len(s) < 2:
        return None
    return [s[-1][i] - s[0][i] for i in (1, 2, 3)], min(x[6] for x in s), max(x[8] for x in s), s[-1][7]


print("  uptime   screen rep >40 worst game | swpin swpout majflt | avail  gtt  swap")
for t, fps, rep, gaps, worst in rows:
    if t < since:
        continue
    g = game.get(round(t), 0.0)
    w = window(t - 10, t)
    mem = (f"{int(w[0][0]):6d} {int(w[0][1]):6d} {int(w[0][2]):6d} | {int(w[1]):5d} {int(w[2]):5d} "
           f"{int(w[3]):5d}") if w else "  (no memory samples)"
    flag = " <-- drop" if rep >= 20 else ""
    print(f"  {t:6.0f}s  {fps:5.1f} {rep:3d} {gaps:3d} {worst:5.0f} {g:4.1f} | {mem}{flag}")
