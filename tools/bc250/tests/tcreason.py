#!/usr/bin/env python3
"""tcreason.py <label>: texture cache churn per route phase from EDEN_NX2_TC_TRACE=1 logs. Per phase: creates,
re-creates (an image created at a GPU address + format + size that was deleted earlier), deletes by reason, uploads,
and for re-creates: the reason the earlier copy was deleted and the median seconds it was gone."""
import re, sys, collections, statistics
L = sys.argv[1]
marks = [(k, float(v)) for k, v in (l.split() for l in open(f"long-{L}.txt"))]
phases = [("load", 0, marks[0][1])] + [(marks[i + 1][0], marks[i][1], marks[i + 1][1]) for i in range(len(marks) - 1)]
def ph(t):
    for n, a, b in phases:
        if a < t <= b: return n
    return "after"
st = collections.defaultdict(collections.Counter); gone = collections.defaultdict(list)
dead = {}
for line in open(f"log-{L}.txt", errors="replace"):
    if "TCTRACE" not in line: continue
    t = float(line[1:line.index("]")]); p = ph(t)
    m = re.search(r"TCTRACE (\w+)", line).group(1)
    g = re.search(r"gpu=(0x[0-9a-f]+)", line); f = re.search(r"fmt=(\d+) (\d+x\d+x\d+)", line)
    key = (g.group(1) if g else None, f.groups() if f else None)
    if m == "delete":
        r = re.search(r"reason=([\w-]+)", line).group(1)
        st[p]["del:" + r] += 1; dead[key] = (t, r)
    elif m == "create":
        st[p]["create"] += 1
        if key in dead:
            t0, r = dead.pop(key); st[p]["recreate"] += 1; st[p]["re<-" + r] += 1; gone[p].append(t - t0)
    elif m == "upload":
        st[p]["upload"] += 1
for n, a, b in phases + [("after", 0, 0)]:
    c = st[n]
    if not c: continue
    s = max(b - a, 1)
    med = statistics.median(gone[n]) if gone[n] else 0
    items = " ".join(f"{k}={v/s:.1f}" for k, v in sorted(c.items()) if k not in ("create", "recreate", "upload"))
    print(f"{n:9} {s:4.0f}s  create/s={c['create']/s:5.1f} recreate/s={c['recreate']/s:5.1f} (gone {med:5.1f}s) upload/s={c['upload']/s:5.1f}  {items}")
