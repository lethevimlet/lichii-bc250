import re
import json
import os
import pathlib
import signal
import subprocess
import time
import sys

HOME = os.environ.get('BC250_HOME', os.path.expanduser('~'))
signal.signal(signal.SIGTERM, lambda *a: sys.exit(0))

launcher = pathlib.Path.home() / 'Applications/Eglantine'
original = launcher.read_bytes()
marker = b'    export EDEN_NX2_PRELOAD_ALL_PIPELINES=0\n'
assert original.count(marker) == 1
assert subprocess.run(['pgrep', '-x', 'eden-cli'], stdout=subprocess.DEVNULL).returncode != 0
for _p in pathlib.Path('/proc').iterdir():
    try:
        if _p.name.isdigit() and b'AppId=3688079378' in (_p / 'cmdline').read_bytes() and (_p / 'comm').read_text().strip() == 'reaper':
            raise SystemExit('a previous Steam launch of the shortcut is still alive: clean it up first')
    except (FileNotFoundError, ProcessLookupError, PermissionError):
        pass
subprocess.run(['podman', 'start', 'bc250-meshbuild'], stdout=subprocess.DEVNULL, check=True)
started = time.monotonic()
reason = 'time limit'
seen = False
try:
    extra = b'    export EDEN_NX2_DEBUG_SERVER=127.0.0.1:6545\n'
    if os.getenv('BC250_TEST_PROFILE') == '1':
        extra += b'    export EDEN_NX2_GPU_PROFILE=1\n'
    if os.getenv('BC250_TEST_GPU_TRACE') == '1':
        extra += b'    export EDEN_DKB_FRAME_TRACE=1\n'
    if os.getenv('BC250_TEST_SHADER_DUMP') == '1':
        extra += b'    export EDEN_NX2_SHADER_DUMP=' + HOME.encode() + b'/.local/share/eden/bc250-test-recordings/compute-analysis/native\n'
    if os.getenv('BC250_TEST_TENSOR_DESCRIBE') == '1':
        extra += b'    export BC250_TENSOR_DESCRIBE=1\n'
    if os.getenv('BC250_TEST_WIDE') == '1':
        extra += b'    export EDEN_NX2_MESH_WIDE_BARRIER=1\n'
    if os.getenv('BC250_TEST_NO_MESH') == '1':
        extra += b'    export EDEN_NX2_NO_MESH=1\n'
    mesh_mode = os.getenv('BC250_TEST_MESH')
    if mesh_mode in ('old', 'new', 'r100', 'r075', 'r050', 'fgon', 'fgoff', 'tensoron', 'tensoroff', 'meshon', 'meshoff'):
        extra += f'    export XDG_CACHE_HOME={HOME}/.cache/bc250-mesh-{mesh_mode}\n'.encode()
        if mesh_mode == 'old':
            extra += b'    export BC250_SKIP_MESH_CACHE=1\n'
    config = None
    modified = original.replace(marker, marker + extra)
    if mesh_mode in ('old', 'new', 'r100', 'r075', 'r050', 'fgon', 'fgoff', 'tensoron', 'tensoroff', 'meshon', 'meshoff'):
        old_bin = re.search(re.escape(HOME.encode()) + rb'/[^ ]*/eden-cli[^ ]*', modified).group(0)
        binary = (HOME + '/oot-bc250-tensor-test/build/bin/eden-cli'
                  if mesh_mode in ('tensoron', 'tensoroff') else
                  HOME + '/oot-bc250-mesh-cache-test/build2/bin/eden-cli')
        tensor_env = 'BC250_TENSOR_STANDIN=1 ' if mesh_mode == 'tensoron' else ''
        new_bin = (f'env XDG_CACHE_HOME={HOME}/.cache/bc250-mesh-{mesh_mode} '
                   f'{tensor_env}{binary}').encode()
        assert modified.count(old_bin) == 1
        modified = modified.replace(old_bin, new_bin)
    import re
    text = pathlib.Path(os.getenv('BC250_TEST_BASE_INI') or pathlib.Path.home() / 'Applications/sharkiix-mesh3.ini').read_text()
    if os.getenv('BC250_TEST_NOFG') == '1':
        assert text.count('\nframe_gen=true\n') == 1
        text = text.replace('\nframe_gen=true\n', '\nframe_gen=false\n')
    edits = list(filter(None, os.getenv('BC250_TEST_INI', '').split(';')))
    resolution = os.getenv('BC250_TEST_RES')
    if resolution:
        edits.append('resolution_setup=' + resolution)
    for line in edits:
        key = line.split('=')[0]
        text, n = re.subn(r'\n' + re.escape(key) + r'=[^\n]*\n', lambda m: '\n' + line + '\n', text)
        assert n == 1, key
        text = text.replace('\n' + key + '\\default=true\n', '\n' + key + '\\default=false\n')
    config = pathlib.Path('/tmp/bc250-test.ini')
    config.write_text(text)
    assert modified.count(b'$APP/sharkiix-mesh3.ini') == 1
    modified = modified.replace(b'$APP/sharkiix-mesh3.ini', b'/tmp/bc250-test.ini')
    for line in filter(None, os.getenv('BC250_TEST_ENV', '').split(';')):
        modified = modified.replace(marker, marker + ('    export ' + line + '\n').encode())
    test_bin = os.getenv('BC250_TEST_BIN')
    if test_bin:
        old_bin = re.search(re.escape(HOME.encode()) + rb'/[^ ]*/eden-cli[^ ]*', modified).group(0)
        assert modified.count(old_bin) == 1 and pathlib.Path(test_bin).is_file()
        modified = modified.replace(old_bin, test_bin.encode())
        # Release packages (eden-bins/rel-*) run natively on the host, as the installer runs them;
        # container builds (built in Fedora 42) need the bc250-meshbuild container.
        box = b"distrobox enter bc250-meshbuild -- "
        modified = modified.replace(box + test_bin.encode(), test_bin.encode())
        if "/eden-bins/cy-" in test_bin:  # CachyOS test container (user reports)
            modified = modified.replace(b"exec " + test_bin.encode(), b"exec distrobox enter cachy-test -- " + test_bin.encode())
        elif "/eden-bins/rt-" in test_bin:  # the installer runtime container
            modified = modified.replace(b"exec " + test_bin.encode(), b"exec distrobox enter lichii-bc250-runtime -- " + test_bin.encode())
        elif "/eden-bins/rel-" not in test_bin:
            assert modified.count(b"exec " + test_bin.encode()) == 1
            modified = modified.replace(b"exec " + test_bin.encode(), b"exec " + box + test_bin.encode())
    launcher.write_bytes(modified)
    subprocess.run(['bash', '-n', str(launcher)], check=True)
    env = os.environ.copy()
    env['DISPLAY'] = ':0'
    game_id = (3688079378 << 32) | 0x02000000
    subprocess.Popen(['steam', f'steam://rungameid/{game_id}'], env=env, start_new_session=True)
    while time.monotonic() - started < int(os.getenv("BC250_RUN_SECONDS", "480")):
        time.sleep(5)
        result = subprocess.run(['pgrep', '-x', 'eden-cli'], capture_output=True, text=True)
        pids = [int(p) for p in result.stdout.split()]
        if pids:
            seen = True
        elif seen:
            reason = 'emulator exited'
            break
        elif time.monotonic() - started > 90:
            reason = 'launch timeout'
            break
        try:
            sensors = {p.read_text().strip(): p.parent for p in pathlib.Path('/sys/class/hwmon').glob('hwmon*/name')}
            temperatures = [int((sensors[name] / 'temp1_input').read_text()) / 1000
                            for name in ('amdgpu', 'k10temp')]
            if any(t >= 85 for t in temperatures):
                reason = 'temperature limit'
                break
            mem = {}
            for line in pathlib.Path('/proc/meminfo').read_text().splitlines():
                key, _, rest = line.partition(':')
                if key in ('MemAvailable', 'SwapFree'):
                    mem[key] = int(rest.split()[0])
            if mem.get('MemAvailable', 0) < 160 * 1024 and mem.get('SwapFree', 0) < 512 * 1024:
                reason = 'memory pressure limit'
                break
        except Exception as e:
            reason = 'monitor failure: ' + str(e)
            break
    print(reason, flush=True)
finally:
    launcher.write_bytes(original)
    result = subprocess.run(['pgrep', '-x', 'eden-cli'], capture_output=True, text=True)
    pids = [int(text) for text in result.stdout.split()]
    for pid in pids:
        try:
            os.kill(pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
    time.sleep(10)
    for pid in pids:
        try:
            if pathlib.Path(f'/proc/{pid}/comm').read_text().strip() == 'eden-cli':
                os.kill(pid, signal.SIGKILL)
        except (ProcessLookupError, FileNotFoundError):
            pass
