import json, sys
d = json.load(sys.stdin)
i = d.get("intervals_ms", [])
print(f"fps {d['fps']:.1f}  frames {d['frames']}  p50 {d['p50_ms']:.1f}  p90 {d['p90_ms']:.1f}  "
      f"p99 {d['p99_ms']:.1f}  max {d['max_ms']:.1f} ms  (last {len(i)}: >34ms {sum(x > 34 for x in i)})")
