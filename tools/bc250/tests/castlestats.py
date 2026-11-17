#!/usr/bin/env python3
"""castlestats.py <label>: per phase of the castle route (long-<label>.txt marks) from log-<label>.txt and t1-<label>.txt:
screen fps, repeated frames/s, worst gap, game fps, min MemAvailable, peak swap, peak GTT, swap-ins, major faults."""
import re, sys
L = sys.argv[1]
marks = [l.split() for l in open(f"long-{L}.txt")]
if any(len(m) != 2 for m in marks):
    sys.exit(f"{L}: route marks without emulator uptime - the game never ran (launch failure?)")
marks = [(k, float(v)) for k, v in marks]
scr = []  # (uptime, presents/s, repeats, worst ms, window s)
gf = []
for line in open(f"log-{L}.txt", errors="replace"):
    m = re.match(r"\[\s*([\d.]+)\]", line)
    if not m:
        continue
    t = float(m.group(1))
    s = re.search(r"Screen: ([\d.]+) presents/s, (\d+) repeated.*worst gap ([\d.]+) ms in ([\d.]+) s", line)
    if s:
        scr.append((t, float(s.group(1)), int(s.group(2)), float(s.group(3)), float(s.group(4))))
    g = re.search(r"Frame gen output: ([\d.]+) game fps", line)
    if g:
        gf.append((t, float(g.group(1))))
t1 = []
for l in open(f"t1-{L}.txt"):
    f = l.split()
    if len(f) >= 11:
        t1.append([float(x) for x in f[:11]])
print(f"{'phase':8} {'secs':>5} {'screen':>6} {'rep/s':>6} {'worst':>7} {'game':>5} | {'minavail':>8} {'swapMB':>6} {'gttMB':>6} {'swpin':>7} {'majflt':>7}")
phases = [("load", 0.0, marks[0][1])] + [(marks[i + 1][0], marks[i][1], marks[i + 1][1]) for i in range(len(marks) - 1)]
tot = []
for name, a, b in phases:
    if b <= a:
        continue
    w = [x for x in scr if a < x[0] <= b + 10]
    g = [x[1] for x in gf if a < x[0] <= b + 10]
    secs = sum(x[4] for x in w) or 1
    pres = sum(x[1] * x[4] for x in w) / secs
    rep = sum(x[2] for x in w) / secs
    worst = max((x[3] for x in w), default=0)
    s = [x for x in t1 if a <= x[0] <= b]
    if s:
        mv = int(min(x[6] for x in s)); sw = int(max(x[7] for x in s)); gt = int(max(x[8] for x in s))
        si = int(s[-1][1] - s[0][1]); mf = int(s[-1][3] - s[0][3])
    else:
        mv = sw = gt = si = mf = 0
    print(f"{name:8} {b - a:5.0f} {pres:6.1f} {rep:6.1f} {worst:7.0f} {sum(g) / len(g) if g else 0:5.1f} | {mv:8} {sw:6} {gt:6} {si:7} {mf:7}")
    if name != "load":
        tot.append((secs, pres, rep, worst))
secs = sum(x[0] for x in tot)
print(f"route: screen {sum(x[0]*x[1] for x in tot)/secs:.1f} fps, {sum(x[0]*x[2] for x in tot)/secs:.1f} repeats/s, worst {max(x[3] for x in tot):.0f} ms")
