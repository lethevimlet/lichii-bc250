# longstats.py <label>: per-minute screen and game stats from the log's 10 s lines during oot-long.sh.
import re
import sys

L = sys.argv[1]
marks = dict(line.split() for line in open(f"long-{L}.txt"))
start, end = int(marks["start"]), int(marks["end"])
screen, game = [], []
for line in open(f"log-{L}.txt", errors="replace"):
    if not line.startswith("["):
        continue
    t = float(line.split("]")[0].strip("[ "))
    if not start <= t <= end + 1:
        continue
    m = re.search(r"Screen: ([\d.]+) presents/s, (\d+) repeated frames.*?(\d+) gaps > 40 ms, "
                  r"worst gap ([\d.]+) ms in ([\d.]+) s", line)
    if m:
        screen.append((t, *map(float, m.groups())))
    m = re.search(r"Frame gen output: ([\d.]+) game fps", line)
    if m:
        game.append((t, float(m.group(1))))
total = [0.0, 0.0, 0.0]
for minute in range((end - start) // 60 + 1):
    a, b = start + minute * 60, start + minute * 60 + 60
    s = [r for r in screen if a <= r[0] < b]
    g = [r[1] for r in game if a <= r[0] < b]
    if not s:
        continue
    secs = sum(r[5] for r in s)
    fps = sum(r[1] * r[5] for r in s) / secs
    rep = sum(r[2] for r in s)
    total[0] += secs; total[1] += rep; total[2] += fps * secs
    print(f"  {L} min {minute}: screen {fps:.1f} fps, repeated {int(rep)} ({rep / secs:.1f}/s), "
          f">40 ms {int(sum(r[3] for r in s))}, worst {max(r[4] for r in s):.0f} ms"
          f" | game {sum(g) / max(1, len(g)):.1f} fps")
if total[0]:
    print(f"  {L} all: screen {total[2] / total[0]:.1f} fps, repeated {total[1] / total[0]:.2f}/s")
