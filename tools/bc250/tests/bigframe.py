#!/usr/bin/env python3
"""bigframe.py <label> [min_ms]: for each stutter-trace frame over min_ms (default 1000), sum the TC trace lines
logged during it: creates (count, ms), uploads (count, ms, read ms, untile ms, page faults, MiB), deletes."""
import re, sys
L = sys.argv[1]; MIN = float(sys.argv[2]) if len(sys.argv) > 2 else 1000
lines = open(f"log-{L}.txt", errors="replace").read().splitlines()
frames = []
for i, l in enumerate(lines):
    if "Nx2Stutter frame=" in l:
        ms = float(re.search(r" ms=([\d.]+)", l).group(1)); t = float(l[1:l.index("]")])
        frames.append((t, ms, i))
for t, ms, i in frames:
    if ms < MIN: continue
    t0 = t - ms / 1000
    c = dict(cr=0, crms=0.0, up=0, upms=0.0, rd=0.0, ut=0.0, fl=0, kib=0, de=0)
    j = i
    while j > 0:
        j -= 1
        l = lines[j]
        m = re.match(r"\[\s*([\d.]+)\]", l)
        if not m: continue
        if float(m.group(1)) < t0: break
        if "TCTRACE create" in l:
            c["cr"] += 1; c["crms"] += float(re.search(r" ms=([\d.]+)", l).group(1))
        elif "TCTRACE upload" in l:
            c["up"] += 1; c["upms"] += float(re.search(r" ms=([\d.]+)", l).group(1))
            c["rd"] += float(re.search(r"read=([\d.]+)", l).group(1)); c["ut"] += float(re.search(r"untile=([\d.]+)", l).group(1))
            c["fl"] += int(re.search(r"faults=(\d+)", l).group(1)); c["kib"] += int(re.search(r"host=(\d+)KiB", l).group(1))
        elif "TCTRACE delete" in l:
            c["de"] += 1
    print(f"t={t:7.1f} frame {ms:6.0f} ms: create {c['cr']} ({c['crms']:.0f} ms), upload {c['up']} ({c['upms']:.0f} ms: read {c['rd']:.0f}, untile {c['ut']:.0f}, faults {c['fl']}, {c['kib']>>10} MiB), deletes {c['de']}")
