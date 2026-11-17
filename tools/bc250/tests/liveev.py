#!/usr/bin/env python3
# liveev.py <state>: one poll of a live play session; prints only notable events since the last poll.
import os, re, sys, json, subprocess, time
st_path = sys.argv[1]
st = json.load(open(st_path)) if os.path.exists(st_path) else {"off": 0, "ino": 0, "running": False, "win": [], "last_sum": 0}
log = os.path.expanduser("~/.local/share/eden/log/eden_log.txt")
running = subprocess.run(["pgrep", "-x", "eden-cli"], capture_output=True).returncode == 0
out = []
if running != st["running"]:
    out.append("GAME STARTED" if running else "GAME CLOSED")
    st["running"] = running
    if running: st["off"] = 0; st["win"] = []; st["last_sum"] = time.time()
try:
    ino = os.stat(log).st_ino
    if ino != st["ino"]: st["ino"] = ino; st["off"] = 0
    with open(log, errors="replace") as f:
        f.seek(st["off"]); data = f.read(); st["off"] = f.tell()
except FileNotFoundError:
    data = ""
for line in data.splitlines():
    m = re.search(r"\[\s*([\d.]+)\].*Screen: ([\d.]+) presents/s, (\d+) repeated.*worst gap ([\d.]+) ms", line)
    if m:
        t, fps, rep, worst = float(m[1]), float(m[2]), int(m[3]), float(m[4])
        st["win"].append([fps, rep, worst])
        if worst >= 1000: out.append(f"PAUSE {worst/1000:.1f} s at {int(t)//60}:{int(t)%60:02d} game time ({fps:.0f} fps that 10 s)")
        continue
    if re.search(r"Device loss|Device fault|texture format=0|<Critical>|<Error>|Killed|out of memory|failed: -2", line) and "unimplemented function" not in line and "Unknown / unimplemented" not in line:
        out.append("LOG: " + line[:200])
for l in open("/proc/swaps").read().splitlines()[1:]:
    f = l.split()
    if f[0].startswith("/var/swap") and int(f[3]) > 204800 and not st.get("disk_warned"):
        out.append(f"DISK SWAP in use: {int(f[3])/1048576:.1f} GB (zram full)"); st["disk_warned"] = True
full10 = float(open("/proc/pressure/memory").read().split("full avg10=")[1].split()[0])
if full10 >= 25 and running:
    out.append(f"MEMORY PRESSURE {full10:.0f}% (box stalls waiting for memory; oomd closes the game at 80% for 20 s)")
if running and time.time() - st["last_sum"] >= 300 and st["win"]:
    w = st["win"]; n = len(w)
    mem = dict(l.split(":")[0:2] for l in open("/proc/meminfo"))
    kb = lambda k: int(mem[k].split()[0])
    free_gb = kb("MemFree") / 1048576
    zl = [l.split() for l in open("/proc/swaps").read().splitlines()[1:] if l.startswith("/dev/zram")]
    zram_gb = sum(int(x[3]) for x in zl) / 1048576; zram_tot = sum(int(x[2]) for x in zl) / 1048576
    swap_used = (kb("SwapTotal") - kb("SwapFree")) / 1048576
    out.append(f"5-min summary: {sum(x[0] for x in w)/n:.1f} screen fps, {sum(x[1] for x in w)/(n*10):.1f} repeats/s, worst {max(x[2] for x in w):.0f} ms; swap used {swap_used:.1f} GB (zram {zram_gb:.1f}/{zram_tot:.1f}), free RAM {free_gb:.1f} GB")
    st["win"] = []; st["last_sum"] = time.time()
json.dump(st, open(st_path, "w"))
print("\n".join(out[:12]))
