# dropstats.py <label>...: 60 fps view of the stutter trace (2x frame gen on FIFO 60 Hz):
# a game frame > 34 ms misses its vsync pair = a visible drop. Per window: drops, missed vsyncs,
# causes, and how many drops coincide with major-fault bursts is left to walkstats.
import sys, re, collections
for L in sys.argv[1:]:
    blocks = open(f"vm-{L}.txt").read().split("== ")[1:]
    up = [int(b.split("uptime")[1].split()[0]) for b in blocks]
    wins = [("walk", up[1], up[2])] + ([("route2", up[2], up[3])] if len(up) > 3 else [])
    rows = []
    for l in open(f"log-{L}.txt", errors="replace"):
        if "Nx2Stutter frame=" not in l: continue
        t = float(l.split("]")[0].strip("[ ")); ms = float(re.search(r"ms=([\d.]+)", l).group(1))
        cause = re.search(r"cause=(\w+)", l).group(1)
        rows.append((t, ms, cause, l))
    for name, a, b in wins:
        w = [r for r in rows if a <= r[0] <= b + 1]
        drops = [r for r in w if r[1] > 34]
        missed = sum(max(0, round(r[1] / 16.67) - 2) for r in drops)
        c = collections.Counter(r[2] for r in drops)
        dur = b - a
        print(f"  {L} {name} ({dur}s): drops>34ms {len(drops)} ({len(drops)/dur:.1f}/s) missed_vsyncs {missed} "
              f">50 {sum(r[1]>50 for r in w)} >100 {sum(r[1]>100 for r in w)} causes {dict(c)}")
