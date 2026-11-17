import sys, collections, re
# kcallers.py: from `perf script` on stdin, kernel samples grouped by the first user-space frame (and the 2nd)
c=collections.Counter(); tot=0; ker=0; cur=[]
def flush():
    global tot, ker
    if not cur: return
    tot+=1
    if cur[0][1]:  # leaf is kernel
        ker+=1
        user=[s for s,k in cur if not k][:2]
        c[" <- ".join(user) or "?"]+=1
for line in sys.stdin:
    if not line.strip():
        flush(); cur=[]; continue
    m=re.match(r'\s+([0-9a-f]+)\s+(.*?)\s+\((.*)\)$', line)
    if m:
        sym=re.sub(r'\+0x[0-9a-f]+$','',m.group(2)); dso=m.group(3)
        kern='kernel' in dso or dso.startswith('[') and 'amdgpu' in dso or sym.startswith('0xffff')
        sym=re.sub(r'\(.*','',sym)[:90]
        cur.append((sym,kern))
flush()
print(f"{ker} kernel of {tot} samples ({100*ker/max(tot,1):.1f}%)")
for k,v in c.most_common(14): print(f"{100*v/tot:5.2f}%  {k}")
