#!/usr/bin/env python3
"""phasecause.py <label>: per route phase (long-<label>.txt), stutter-trace frames (EDEN_NX2_STUTTER_TRACE=1)
over 40 ms: count by cause, summed component ms (texture, buffer, query_fence, other, gfx/compute miss) per second,
avg back-thread busy in slow frames, and swap-ins (t1-<label>.txt col 2 = cumulative swap-ins)."""
import re, sys, collections
L = sys.argv[1]
marks = [(k, float(v)) for k, v in (l.split() for l in open(f"long-{L}.txt"))]
phases = [(marks[i + 1][0], marks[i][1], marks[i + 1][1]) for i in range(len(marks) - 1)]
fr = []
for line in open(f"log-{L}.txt", errors="replace"):
    if "Nx2Stutter " not in line:
        continue
    t = float(line[1:line.index("]")])
    d = dict(re.findall(r" (\w+)=([\d.]+)(?=[ ,]|$)", line))
    c = re.search(r"cause=(\w+)", line).group(1)
    back = re.search(r"back:([\d.]+)", line)
    fr.append((t, float(d["ms"]), c, d, float(back.group(1)) if back else 0))
t1 = [[float(x) for x in l.split()[:3]] for l in open(f"t1-{L}.txt") if len(l.split()) >= 3]
def swapin(a, b):
    v = [r[1] for r in t1 if a <= r[0] <= b]
    return int(v[-1] - v[0]) if len(v) > 1 else 0
keys = ["texture", "buffer", "query_fence", "other", "gfx_miss", "compute_miss", "pipeline_wait", "present"]
print(f"{'phase':9} {'s':>3} {'>40':>4} {'>70':>4}  causes                         | ms/s: " + " ".join(f"{k[:7]:>7}" for k in keys) + f" | {'back':>5} {'swpin':>6}")
for name, a, b in phases:
    sel = [f for f in fr if a < f[0] <= b and f[1] > 40]
    cz = collections.Counter(f[2] for f in sel)
    secs = max(b - a, 1)
    comp = [sum(float(f[3].get(k, 0)) for f in sel) / secs for k in keys]
    back = sum(f[4] for f in sel) / len(sel) if sel else 0
    cs = ",".join(f"{k}:{v}" for k, v in cz.most_common(4))
    print(f"{name:9} {secs:3.0f} {len(sel):4} {sum(f[1] > 70 for f in sel):4}  {cs:30} | ms/s: " + " ".join(f"{x:7.1f}" for x in comp) + f" | {back:5.1f} {swapin(a, b):6}")
