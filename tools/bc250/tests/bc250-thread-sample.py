import pathlib
import subprocess
import time

pid = int(subprocess.check_output(['pgrep', '-x', 'eden-cli'], text=True).strip())
root = pathlib.Path(f'/proc/{pid}/task')
def sample():
    out = {}
    for task in root.iterdir():
        try:
            stat = (task / 'stat').read_text()
            name, fields = stat[stat.index('(')+1:stat.rindex(')')], stat[stat.rindex(')')+2:].split()
            out[int(task.name)] = (name, int(fields[11]) + int(fields[12]))
        except (FileNotFoundError, ProcessLookupError):
            pass
    return out
a = sample()
start = time.monotonic()
time.sleep(15)
b = sample()
elapsed = time.monotonic() - start
hz = int(subprocess.check_output(['getconf', 'CLK_TCK'], text=True))
for tid, (name, ticks) in sorted(b.items(), key=lambda x: x[1][1] - a.get(x[0], ('', x[1][1]))[1], reverse=True)[:12]:
    if tid in a:
        print(f'{name}: {(ticks-a[tid][1])/hz/elapsed*100:.1f}% of one CPU')
