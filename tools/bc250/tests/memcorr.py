# memcorr.py <label>: per 10 s window of the "Device memory 10 s" log line: new GPU memory blocks and MiB
# against swap-outs, swap-ins, major faults, compaction stalls (t1watch) and screen repeats; then
# correlations over the session.
import re
import sys

L = sys.argv[1]
samples = [list(map(float, l.split())) for l in open(f"t1-{L}.txt") if len(l.split()) >= 11]
traffic, screen = [], []
for line in open(f"log-{L}.txt", errors="replace"):
    try:
        t = float(line.split("]")[0].strip("[ "))
    except ValueError:
        continue
    if m := re.search(r"Device memory 10 s: (\d+) new blocks (\d+) MiB \((\d+) >= 8 MiB.*?worst ([\d.]+) ms\), "
                      r"(\d+) reused from the reserve, (\d+) freed", line):
        traffic.append((t, *map(float, m.groups())))
    elif m := re.search(r"Screen: [\d.]+ presents/s, (\d+) repeated", line):
        screen.append((t, int(m.group(1))))


def delta(a, b, i):
    s = [x for x in samples if a <= x[0] <= b]
    return s[-1][i] - s[0][i] if len(s) >= 2 else 0.0


rows = []
print("  uptime  blocks  MiB big worst reuse frees | swpout  swpin majflt cmpct | repeats")
for t, n, mib, big, worst, reuse, frees in traffic:
    a = t - 10
    so, si, mj, cs = delta(a, t, 2), delta(a, t, 1), delta(a, t, 3), delta(a, t, 5)
    rep = sum(r for ts, r in screen if a < ts <= t + 1)
    rows.append((n, mib, so, si, mj, rep))
    print(f"  {t:6.0f}s {int(n):6d} {int(mib):5d} {int(big):3d} {worst:5.1f} {int(reuse):5d} {int(frees):5d} | "
          f"{int(so):6d} {int(si):6d} {int(mj):6d} {int(cs):5d} | {rep:4d}")


def corr(x, y):
    n = len(x)
    if n < 3:
        return float("nan")
    mx, my = sum(x) / n, sum(y) / n
    sx = sum((v - mx) ** 2 for v in x) ** 0.5
    sy = sum((v - my) ** 2 for v in y) ** 0.5
    return sum((a - mx) * (b - my) for a, b in zip(x, y)) / (sx * sy) if sx and sy else float("nan")


cols = list(zip(*rows)) if rows else []
if cols:
    print(f"  correlation over {len(rows)} windows: MiB allocated vs swap-out {corr(cols[1], cols[2]):.2f}, "
          f"blocks vs swap-out {corr(cols[0], cols[2]):.2f}, swap-in vs repeats {corr(cols[3], cols[5]):.2f}, "
          f"MiB allocated vs repeats {corr(cols[1], cols[5]):.2f}")
