# smapsum.py <smaps file>: private (anonymous/heap) memory of a process grouped by kind.
import sys, re, collections
groups = collections.defaultdict(lambda: [0, 0, 0])  # rss kB, swap kB, count
big = []
cur = None
for line in open(sys.argv[1]):
    m = re.match(r'^([0-9a-f]+)-([0-9a-f]+) (\S+) \S+ \S+ \d+\s*(.*)$', line)
    if m:
        a, b, perms, name = int(m[1], 16), int(m[2], 16), m[3], m[4].strip()
        size = (b - a) >> 10
        if name.startswith('/memfd:HostMemory'): kind = 'guest memory (memfd, shared)'
        elif name.startswith('/memfd:') or name.startswith('/dev/dri') or 'drm' in name: kind = f'GPU/driver shared ({name.split()[0][:30]})'
        elif name == '[heap]': kind = 'C heap [heap]'
        elif name.startswith('[stack'): kind = 'stacks'
        elif name == '': 
            if 'x' in perms: kind = 'anon executable (JIT code caches)'
            elif size >= 65536 and size <= 65536 + 4 and perms.startswith('rw'): kind = 'anon 64 MiB (malloc thread arenas)'
            else: kind = 'anon other'
        elif name.startswith('/'): kind = 'file-backed: ' + name.split('/')[-1][:40]
        else: kind = 'other ' + name[:30]
        cur = [kind, size, perms, name, 0, 0]
        continue
    if cur is None: continue
    k, v = line.split(':', 1)
    if k == 'Rss': cur[4] = int(v.split()[0])
    elif k == 'Swap':
        cur[5] = int(v.split()[0])
        g = groups[cur[0]]; g[0] += cur[4]; g[1] += cur[5]; g[2] += 1
        big.append((cur[4] + cur[5], cur[0], cur[1], cur[2], cur[4], cur[5]))
tot = sum(g[0] for g in groups.values())
print(f'total RSS {tot>>10} MiB')
for kind, (rss, swap, n) in sorted(groups.items(), key=lambda x: -(x[1][0] + x[1][1]))[:16]:
    print(f'{rss>>10:7} MiB RSS {swap>>10:6} MiB swap {n:6} maps  {kind}')
print('largest private mappings (anon):')
for s, kind, size, perms, rss, swap in sorted([b for b in big if not b[1].startswith('guest') and not b[1].startswith('file')], reverse=True)[:12]:
    print(f'  {rss>>10:6} MiB RSS {swap>>10:5} MiB swap  size {size>>10:6} MiB {perms} {kind}')
