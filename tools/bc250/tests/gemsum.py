# gemsum.py: summarise /sys/kernel/debug/dri/1/amdgpu_gem_info (stdin): per process MiB by
# preferred domain, and for eden-cli the largest buffers and a size histogram.
import sys, re, collections
procs = collections.OrderedDict(); cur = None; bos = collections.defaultdict(list)
for line in sys.stdin:
    m = re.match(r'pid\s+(\d+) command (.*):', line)
    if m:
        cur = f'{m[2]}[{m[1]}]'; procs.setdefault(cur, collections.Counter()); continue
    m = re.match(r'\s+0x[0-9a-f]+:\s+(\d+) byte (\w+)', line)
    if m and cur:
        size, dom = int(m[1]), m[2]
        procs[cur][dom] += size; procs[cur]['n'] += 1
        bos[cur].append((size, line.split('byte', 1)[1].split('\t')[0].strip()))
tot = collections.Counter()
for p, c in procs.items():
    print(f'{p:28s} n={c["n"]:6d} GTT {c["GTT"] >> 20:6d} MiB  VRAM {c["VRAM"] >> 20:6d} MiB')
    for k in ('GTT', 'VRAM'): tot[k] += c[k]
print(f'{"total":28s}          GTT {tot["GTT"] >> 20:6d} MiB  VRAM {tot["VRAM"] >> 20:6d} MiB')
for p in procs:
    if not p.startswith('eden-cli'): continue
    b = sorted(bos[p], reverse=True)
    hist = collections.Counter()
    for s, f in b:
        k = '>=64M' if s >= 64 << 20 else '8-64M' if s >= 8 << 20 else '1-8M' if s >= 1 << 20 else '<1M'
        hist[k] += s
    print(p, 'by size:', {k: v >> 20 for k, v in hist.items()})
    print('  largest:', [(s >> 20, f.split()[0]) for s, f in b[:25]])
    # same-size groups (many equal allocations = pools/arenas)
    g = collections.Counter(s for s, f in b)
    print('  repeated sizes (MiB x count):', [(s >> 20 if s >= 1 << 20 else round(s / 1048576, 2), n) for s, n in g.most_common(12) if s * n >= 16 << 20])
