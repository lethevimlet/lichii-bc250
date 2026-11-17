# t1stats.py <label>: per 10 s "Screen:" window from 60 s before the long test's start to its end: screen
# repeats, game fps, swap-ins/outs, major faults, reclaim stalls, MemAvailable min, GTT max, pipeline builds,
# texture uploads and the stutter trace's slow-frame causes.
import collections
import re
import sys

L = sys.argv[1]
marks = dict(line.split() for line in open(f"long-{L}.txt"))
start, end = int(marks["start"]), int(marks["end"])
samples = [list(map(float, line.split())) for line in open(f"t1-{L}.txt") if len(line.split()) >= 11]
screen, game, slow, builds = [], [], [], []
for line in open(f"log-{L}.txt", errors="replace"):
    if not line.startswith("["):
        continue
    t = float(line.split("]")[0].strip("[ "))
    if m := re.search(r"Screen: ([\d.]+) presents/s, (\d+) repeated", line):
        screen.append((t, float(m.group(1)), int(m.group(2))))
    elif m := re.search(r"Frame gen output: ([\d.]+) game fps", line):
        game.append((t, float(m.group(1))))
    elif "Nx2Stutter frame=" in line:
        ms = float(re.search(r"ms=([\d.]+)", line).group(1))
        cause = re.search(r"cause=(\w+)", line).group(1)
        slow.append((t, ms, cause))
    elif re.search(r"[Pp]ipeline.*(built|compil)", line):
        builds.append(t)


def window(a, b):
    s = [x for x in samples if a <= x[0] <= b]
    if len(s) < 2:
        return None
    d = [s[-1][i] - s[0][i] for i in range(1, 6)]
    return d, min(x[6] for x in s), max(x[8] for x in s), s[-1][7]


print(f"{L}: start {start} end {end} (emulator uptime s)")
print("  window      repeats game | swpin  swpout majflt stall cmpct | avail swap  gtt | >34ms causes")
for t, fps, rep in screen:
    if not start - 60 <= t <= end + 1:
        continue
    a, b = t - 10, t
    w = window(a, b)
    g = [x[1] for x in game if abs(x[0] - t) < 1]
    c = collections.Counter(x[2] for x in slow if a <= x[0] < b and x[1] > 34)
    tag = "pre " if t < start else "    "
    if w:
        d, avail, gtt, swap = w
        print(f"  {tag}{a - start:+5.0f}..{b - start:+4.0f}  {rep:4d} {g[0] if g else 0:4.1f} | {int(d[0]):6d} {int(d[1]):6d} {int(d[2]):6d} {int(d[3]):5d} {int(d[4]):5d} | {int(avail):5d} {int(swap):5d} {int(gtt):5d} | {dict(c)}")
