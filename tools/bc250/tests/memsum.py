# memsum.py <fps-sampler log>: min MemAvailable, max swap, and seconds under 15 / 25 fps (per sample)
import sys
rows = [l.split() for l in open(sys.argv[1]) if ' fps ' in l]
fps = [int(r[2]) / 1.65 for r in rows]          # samples are ~1.65 s apart
avail = [int(r[4]) for r in rows]; swap = [int(r[5]) for r in rows]; gtt = [int(r[7]) for r in rows]
print(f"samples {len(rows)}  min_avail {min(avail)} MB  swap {swap[0]}->{max(swap)} MB  max_gtt {max(gtt)} MB  "
      f"samples<15fps {sum(f < 15 for f in fps)}  <25fps {sum(f < 25 for f in fps)}")
