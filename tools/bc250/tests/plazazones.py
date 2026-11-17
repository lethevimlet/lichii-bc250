import re,sys,collections
# plazazones.py <phase> <label>...: aggregate Nx2StutterDetail zones/sites for slow frames inside <phase>
ph=sys.argv[1]
order=['start','in1','town1','plaza1','out1','field1','in2','town2','plaza2','end']
Z=collections.Counter(); S=collections.Counter(); N=0; ms_tot=0; secs=0
for L in sys.argv[2:]:
    m={}
    for l in open(f"long-{L}.txt"):
        k,v=l.split(); m[k]=float(v)
    a=m[ph]+3; b=m[order[order.index(ph)+1]]; secs+=b-a
    for line in open(f"log-{L}.txt",errors='replace'):
        if 'Nx2StutterDetail' not in line: continue
        t=float(line[1:line.index(']')])
        if not a<t<b: continue
        N+=1; ms_tot+=float(re.search(r' ms=([\d.]+)',line).group(1))
        zm=re.search(r'zones=(\S+)',line)
        if zm:
            for part in zm.group(1).split(';'):
                th,_,items=part.partition(':')
                for it in items.split(','):
                    mm=re.match(r'(.+) ([\d.]+)/(\d+)$',it)
                    if mm: Z[f"{th}:{mm.group(1)}"]+=float(mm.group(2))
        sm=re.search(r'sites=(\S+)',line)
        if sm:
            for it in sm.group(1).split(','):
                mm=re.match(r'(\w+):(\d+)x([\d.]+)',it)
                if mm: S[mm.group(1)]+=float(mm.group(3))
print(f"{ph}: {N} slow frames in {secs:.0f} s ({N/secs:.1f}/s), avg {ms_tot/max(N,1):.1f} ms")
for k,v in Z.most_common(18): print(f"  {v/N:6.2f} ms/frame  {k}")
print(" sites:", ", ".join(f"{k} {v/N:.2f}" for k,v in S.most_common(8)))
