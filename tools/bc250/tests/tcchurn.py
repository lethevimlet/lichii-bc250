#!/usr/bin/env python3
"""tcchurn.py <label> [phase...]: from an EDEN_NX2_TC_TRACE=1 log, per route phase: images created by
(format, size, type) with how many were re-creations of a deleted image at the same address, the delete reasons
of those, and the guest MiB involved. Shows what the GPU memory churn is made of."""
import re, sys, collections
L = sys.argv[1]; want = set(sys.argv[2:])
marks = [(k, float(v)) for k, v in (l.split() for l in open(f"long-{L}.txt"))]
phases = [(marks[i + 1][0], marks[i][1], marks[i + 1][1]) for i in range(len(marks) - 1)]
def ph(t):
    for n, a, b in phases:
        if a < t <= b: return n
dead = {}; per = collections.defaultdict(lambda: collections.defaultdict(lambda: [0, 0, 0, collections.Counter()]))
for line in open(f"log-{L}.txt", errors="replace"):
    if "TCTRACE" not in line: continue
    t = float(line[1:line.index("]")]); p = ph(t)
    m = re.search(r"TCTRACE (\w+)", line).group(1)
    g = re.search(r"gpu=(0x[0-9a-f]+)", line); f = re.search(r"fmt=(\d+) (\d+x\d+x\d+)", line)
    if not g or not f: continue
    key = (g.group(1),) + f.groups()
    if m == "delete":
        dead[key] = re.search(r"reason=([\w-]+)", line).group(1)
    elif m == "create" and p and (not want or p in want):
        ty = re.search(r"type=(\d+)", line).group(1); kib = int(re.search(r"guest=(\d+)KiB", line).group(1))
        e = per[p][(f.group(1), f.group(2), ty)]
        e[0] += 1; e[2] += kib
        if key in dead:
            e[1] += 1; e[3][dead.pop(key)] += 1
for n, a, b in phases:
    if n not in per: continue
    s = max(b - a, 1); rows = sorted(per[n].items(), key=lambda kv: -kv[1][2])
    tot = sum(v[2] for v in per[n].values()) / 1024
    print(f"== {n} ({s:.0f} s): {sum(v[0] for v in per[n].values())} creates, {tot:.0f} MiB guest ({tot/s:.0f} MiB/s)")
    for (fm, sz, ty), (c, r, kib, why) in rows[:10]:
        print(f"   fmt {fm:>3} {sz:>14} type {ty}: {c:5} created ({c/s:5.1f}/s), {r:5} re-created, {kib/1024:7.0f} MiB  {dict(why)}")
