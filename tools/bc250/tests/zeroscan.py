# zeroscan.py <pid>: in the guest memory backing (memfd "HostMemory"), counts resident pages and
# the resident pages that hold only zeros. Reads only resident pages (pagemap bit 63 = present,
# bit 62 = swapped), so it doesn't fault anything in. Read-only.
import sys, struct, os
pid = int(sys.argv[1])
maps = [l.split() for l in open(f'/proc/{pid}/maps')]
regions = []
for m in maps:
    if len(m) >= 6 and 'memfd:HostMemory' in ' '.join(m[5:]):
        a, b = (int(x, 16) for x in m[0].split('-'))
        regions.append((a, b, int(m[2], 16)))
# The backing is the largest mapping at file offset 0; views map parts of it again.
regions.sort(key=lambda r: -(r[1] - r[0]))
start, end, _ = regions[0]
print(f'backing {(end-start)>>20} MiB, {len(regions)} memfd mappings')
pm = open(f'/proc/{pid}/pagemap', 'rb'); mem = open(f'/proc/{pid}/mem', 'rb')
zero = bytes(4096); present = swapped = zeros = 0
CH = 1 << 20  # pages per pagemap read chunk (4 GiB)
addr = start
while addr < end:
    n = min(CH, (end - addr) >> 12)
    pm.seek((addr >> 12) * 8); data = pm.read(n * 8)
    for i in range(n):
        e = struct.unpack_from('<Q', data, i * 8)[0]
        if e >> 63:
            present += 1
            mem.seek(addr + i * 4096)
            try:
                if mem.read(4096) == zero: zeros += 1
            except OSError: pass
        elif (e >> 62) & 1:
            swapped += 1
    addr += n << 12
print(f'resident {present*4096>>20} MiB, of which all-zero {zeros*4096>>20} MiB; swapped {swapped*4096>>20} MiB')
