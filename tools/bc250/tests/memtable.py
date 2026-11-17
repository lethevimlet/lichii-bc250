#!/usr/bin/env python3
import os
# memtable.py <label>: memtrack-<label>.txt as a table of the largest categories over time (MiB, RSS + swap).
import re, sys
L = sys.argv[1]
cur = None; rows = {}; order = []
for l in open(os.path.expanduser(f"~/oot-bc250-tests/memtrack-{L}.txt")):
    m = re.match(r"== t=(\d+)", l)
    if m: cur = int(m[1]); order.append(cur); rows[cur] = {}; continue
    m = re.match(r"\s+(\d+) MiB RSS\s+(\d+) MiB swap\s+\d+ maps\s+(.*)", l)
    if m and cur is not None: rows[cur].setdefault(m[3].strip(), int(m[1]) + int(m[2]))
cats = sorted({k for r in rows.values() for k in r}, key=lambda k: -max(r.get(k, 0) for r in rows.values()))[:7]
print("t(s) " + " | ".join(c[:20] for c in cats) + " | total")
for t in order:
    print(f"{t:<5}" + " | ".join(f"{rows[t].get(c, 0):>20}" for c in cats) + f" | {sum(rows[t].values()):>6}")
