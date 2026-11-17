#!/usr/bin/env python3
"""phasework.py <label>: per route phase, GPU-side work from the log: ASTC GPU decodes, new device memory (MiB),
slow device allocations, pipelines created (MakePipeline tessellation warning = one per build), staging buffers
created, image recycling evictions."""
import re, sys, collections
L = sys.argv[1]
marks = [(k, float(v)) for k, v in (l.split() for l in open(f"long-{L}.txt"))]
phases = [("load", 0, marks[0][1])] + [(marks[i + 1][0], marks[i][1], marks[i + 1][1]) for i in range(len(marks) - 1)]
ev = []
for line in open(f"log-{L}.txt", errors="replace"):
    m = re.match(r"\[\s*([\d.]+)\]", line)
    if not m: continue
    t = float(m.group(1))
    if (x := re.search(r"ASTC GPU decodes: (\d+) in (\d+) ms", line)): ev.append((t, "astc", int(x.group(1)), int(x.group(2)) / 1000))
    elif (x := re.search(r"Device memory 10 s: (\d+) new blocks (\d+) MiB", line)): ev.append((t, "devmem", int(x.group(2)), 10))
    elif "Slow device memory allocation" in line: ev.append((t, "slowalloc", 1, 0))
    elif "Patch topology not used" in line: ev.append((t, "pipe", 1, 0))
    elif (x := re.search(r"Staging buffers 10 s: (\d+) created \((\d+) MiB", line)): ev.append((t, "stagemib", int(x.group(2)), 10))
def rate(kind, a, b):
    tot = 0.0
    for t, k, v, span in ev:
        if k != kind: continue
        if span == 0:
            tot += v if a < t <= b else 0
        else:  # count per window, spread uniformly
            lo, hi = t - span, t
            ov = max(0, min(b, hi) - max(a, lo))
            tot += v * ov / span
    return tot / max(b - a, 1)
print(f"{'phase':9} {'s':>4} {'astc/s':>7} {'devMiB/s':>8} {'slowall/s':>9} {'pipes/s':>7} {'stageMiB/s':>10}")
for n, a, b in phases:
    print(f"{n:9} {b-a:4.0f} {rate('astc',a,b):7.1f} {rate('devmem',a,b):8.1f} {rate('slowalloc',a,b):9.2f} {rate('pipe',a,b):7.2f} {rate('stagemib',a,b):10.1f}")
