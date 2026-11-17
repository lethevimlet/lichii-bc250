import re,sys,collections
# playcause.py <label>...: stutter-trace frames in gameplay phases (plaza1, field1, town2, plaza2; first 3 s skipped)
for L in sys.argv[1:]:
    m=dict(l.split() for l in open(f"long-{L}.txt"))
    m={k:float(v) for k,v in m.items()}
    win=[(m['plaza1']+3,m['out1']),(m['field1']+3,m['in2']),(m['town2']+3,m['plaza2']),(m['plaza2']+3,m['end'])]
    n=collections.Counter(); big=collections.Counter(); comp=collections.Counter(); secs=sum(b-a for a,b in win)
    for line in open(f"log-{L}.txt",errors='replace'):
        if 'Nx2Stutter ' not in line: continue
        t=float(line[1:line.index(']')])
        if not any(a<t<b for a,b in win): continue
        ms=float(re.search(r' ms=([\d.]+)',line).group(1)); c=re.search(r'cause=(\w+)',line).group(1)
        n[c]+=1
        if ms>50: big[c]+=1
        for k in ('texture','buffer','other','query_fence','present','gfx_miss','compute_miss','pipeline_wait'):
            comp[k]+=float(re.search(rf' {k}=([\d.]+)',line).group(1))
    print(L, f"{secs:.0f}s", 'frames', dict(n), '>50ms', dict(big), 'ms by part', {k:round(v) for k,v in comp.items()})
