import os
import pathlib
import signal
import subprocess
import time

command = ['cmake', '--build', os.getenv('BC250_BUILD_DIR', os.path.expanduser('~/oot-bc250-mesh-cache-test/build2')),
           '--parallel', '6', '--target', os.getenv('BC250_BUILD_TARGET', 'eden-cli')] + (['--', '-k', '0'] if os.getenv('BC250_BUILD_KEEPGOING') else [])
proc = subprocess.Popen(command, start_new_session=True)
start = time.monotonic()
reason = None
while proc.poll() is None:
    time.sleep(5)
    try:
        sensors = {p.read_text().strip(): p.parent for p in pathlib.Path('/sys/class/hwmon').glob('hwmon*/name')}
        temperatures = [int((sensors[name] / 'temp1_input').read_text()) / 1000
                        for name in ('amdgpu', 'k10temp')]
        if max(temperatures) >= 85:
            reason = 'temperature limit'
        elif time.monotonic() - start >= int(os.getenv("BC250_BUILD_SECONDS", "3000")):
            reason = 'runtime limit'
    except Exception as exc:
        reason = f'temperature monitoring failed: {exc}'
    if reason:
        print(reason, flush=True)
        os.killpg(proc.pid, signal.SIGTERM)
        try:
            proc.wait(timeout=15)
        except subprocess.TimeoutExpired:
            os.killpg(proc.pid, signal.SIGKILL)
            proc.wait()
        raise SystemExit(1)
raise SystemExit(proc.returncode)
