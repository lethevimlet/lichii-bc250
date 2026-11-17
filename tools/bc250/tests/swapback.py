# swapback.py <pid> [floor_mb] [rate_mb_s]: pull a running emulator's swapped-out memory back into free RAM.
# Root only. Reads, never writes:
#   1. its memfd files (the guest's RAM): data extents via SEEK_DATA/SEEK_HOLE (holes are skipped, so
#      nothing new is allocated), mincore() on a private read-only mapping finds non-resident pages,
#      pread() swaps them in;
#   2. its anonymous memory: /proc/PID/pagemap swap bit, /proc/PID/mem read swaps the page in.
# Stops when MemAvailable falls under floor_mb (default 1500); throttled to rate_mb_s (default 150).
import ctypes
import mmap
import os
import struct
import sys
import time

PID = int(sys.argv[1])
FLOOR = int(sys.argv[2]) if len(sys.argv) > 2 else 1500
RATE = (int(sys.argv[3]) if len(sys.argv) > 3 else 150) << 20
PAGE = 4096
CHUNK = 2 << 20
libc = ctypes.CDLL("libc.so.6", use_errno=True)
libc.mincore.argtypes = [ctypes.c_void_p, ctypes.c_size_t, ctypes.c_char_p]
libc.mmap.restype = ctypes.c_void_p
libc.mmap.argtypes = [ctypes.c_void_p, ctypes.c_size_t, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_long]
libc.munmap.argtypes = [ctypes.c_void_p, ctypes.c_size_t]
os.nice(19)


def avail_mb():
    for line in open("/proc/meminfo"):
        if line.startswith("MemAvailable:"):
            return int(line.split()[1]) // 1024
    return 0


done = 0
start = time.monotonic()


def throttle(nbytes):
    global done
    done += nbytes
    ahead = done / RATE - (time.monotonic() - start)
    if ahead > 0:
        time.sleep(ahead)


def stop():
    return avail_mb() < FLOOR or not os.path.exists(f"/proc/{PID}")


def memfds():
    seen = set()
    for fd in os.listdir(f"/proc/{PID}/fd"):
        try:
            target = os.readlink(f"/proc/{PID}/fd/{fd}")
            st = os.stat(f"/proc/{PID}/fd/{fd}")
        except OSError:
            continue
        if target.startswith("/memfd:") and st.st_ino not in seen and st.st_size > 0:
            seen.add(st.st_ino)
            yield fd, target, st.st_size


def pull_memfd(fd, name, size):
    f = os.open(f"/proc/{PID}/fd/{fd}", os.O_RDONLY)
    pulled = 0
    try:
        base = libc.mmap(None, size, mmap.PROT_READ, mmap.MAP_SHARED, f, 0)
        if base in (None, ctypes.c_void_p(-1).value):
            return 0, False
        vec = ctypes.create_string_buffer(CHUNK // PAGE)
        off = 0
        while off < size:
            try:
                data = os.lseek(f, off, os.SEEK_DATA)
            except OSError:
                break
            hole = os.lseek(f, data, os.SEEK_HOLE)
            pos = data & ~(PAGE - 1)
            while pos < hole:
                if stop():
                    return pulled, True
                n = min(CHUNK, hole - pos)
                n = (n + PAGE - 1) & ~(PAGE - 1)
                if libc.mincore(ctypes.c_void_p(base + pos), n, vec) != 0:
                    pos += n
                    continue
                flags = vec.raw[: n // PAGE]
                i = 0
                while i < len(flags):
                    if flags[i] & 1:
                        i += 1
                        continue
                    j = i
                    while j < len(flags) and not flags[j] & 1:
                        j += 1
                    os.pread(f, (j - i) * PAGE, pos + i * PAGE)
                    pulled += (j - i) * PAGE
                    throttle((j - i) * PAGE)
                    i = j
                pos += n
            off = hole
        libc.munmap(ctypes.c_void_p(base), size)
    finally:
        os.close(f)
    return pulled, False


def pull_anon():
    pulled = 0
    pm = os.open(f"/proc/{PID}/pagemap", os.O_RDONLY)
    mem = os.open(f"/proc/{PID}/mem", os.O_RDONLY)
    try:
        for line in open(f"/proc/{PID}/maps"):
            parts = line.split()
            lo, hi = (int(x, 16) for x in parts[0].split("-"))
            if len(parts) > 5 or "r" not in parts[1]:  # file-backed / memfd / named: skip
                continue
            for page in range(lo, hi, CHUNK):
                if stop():
                    return pulled, True
                n = min(CHUNK, hi - page) // PAGE
                raw = os.pread(pm, n * 8, (page // PAGE) * 8)
                for k, (entry,) in enumerate(struct.iter_unpack("<Q", raw)):
                    if entry & (1 << 62):  # swapped
                        try:
                            os.pread(mem, 1, page + k * PAGE)
                        except OSError:
                            pass
                        pulled += PAGE
                        throttle(PAGE)
    finally:
        os.close(pm)
        os.close(mem)
    return pulled, False


t0 = time.monotonic()
print(f"start: MemAvailable {avail_mb()} MB", flush=True)
total = 0
for fd, name, size in memfds():
    got, stopped = pull_memfd(fd, name, size)
    total += got
    print(f"memfd {name} ({size >> 20} MiB): pulled {got >> 20} MiB in, MemAvailable {avail_mb()} MB",
          flush=True)
    if stopped:
        print("stopped at the memory floor", flush=True)
        sys.exit(0)
got, stopped = pull_anon()
total += got
print(f"anon: pulled {got >> 20} MiB in{' (stopped at the floor)' if stopped else ''}; "
      f"total {total >> 20} MiB in {time.monotonic() - t0:.0f} s, MemAvailable {avail_mb()} MB", flush=True)
