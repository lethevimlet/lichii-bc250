# vmapeak.py <vma json>: break a vmaBuildStatsString(detailed) dump down by allocation kind.
import sys, json, collections
d = json.load(open(sys.argv[1]))
BUF = {0x1: 'xfer_src', 0x2: 'xfer_dst', 0x4: 'uniform_texel', 0x8: 'storage_texel', 0x10: 'uniform',
       0x20: 'storage', 0x40: 'index', 0x80: 'vertex', 0x100: 'indirect', 0x20000: 'device_address'}
def kind(a):
    t = a.get('Type', '?')
    u = a.get('Usage', 0)
    if t == 'BUFFER' and isinstance(u, int):
        names = [n for b, n in BUF.items() if u & b and n != 'device_address']
        return 'buffer:' + '+'.join(names) if names else 'buffer:?'
    return t if not isinstance(u, int) else f'{t}:{u:#x}'
tot = collections.Counter(); cnt = collections.Counter(); big = []
blocks = free = 0
def walk(o, path):
    global blocks, free
    if isinstance(o, dict):
        if 'Suballocations' in o:
            blocks += o.get('TotalBytes', 0)
            for a in o['Suballocations']:
                if a.get('Type') == 'FREE':
                    free += a['Size']; continue
                k = 'pooled ' + kind(a); tot[k] += a['Size']; cnt[k] += 1; big.append((a['Size'], k, a.get('Name', '')))
            return
        for k, v in o.items():
            walk(v, path + [k])
    elif isinstance(o, list):
        dedicated = path and path[-1] == 'DedicatedAllocations'
        for a in o:
            if dedicated and isinstance(a, dict) and 'Size' in a:
                k = 'dedicated ' + kind(a); tot[k] += a['Size']; cnt[k] += 1; big.append((a['Size'], k, a.get('Name', '')))
            else:
                walk(a, path)
walk(d, [])
M = lambda b: b >> 20
print(f"pooled blocks {M(blocks)} MiB, free inside them {M(free)} MiB; allocations {M(sum(tot.values()))} MiB")
for k, v in tot.most_common(): print(f'  {M(v):6d} MiB  {cnt[k]:5d}  {k}')
print('largest:'); [print(f'  {M(s):5d} MiB  {k} {n}') for s, k, n in sorted(big, reverse=True)[:20]]
tl = d.get('Total', {})
print('Total:', {k: v for k, v in tl.items() if not isinstance(v, dict)})
