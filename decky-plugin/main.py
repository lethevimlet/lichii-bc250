# Lichii BC-250 Decky plugin, the root side: BC-250 tuning, the emulator and plugin updates from
# GitHub releases, the games folder, the per-game configs. Steam shortcuts are made by the frontend
# (SteamClient lives there); this side remembers which shortcut belongs to which game.
import asyncio
import base64
import glob
import hashlib
import json
import os
import re
import shutil
import ssl
import struct
import subprocess
import tempfile
import urllib.request
import zipfile

import decky

# Decky points LD_LIBRARY_PATH at its bundled libraries, older than the system's on some
# distributions: a system program started from here would load them and fail before it runs.
_original_library_path = os.environ.pop("LD_LIBRARY_PATH_ORIG", None)
if _original_library_path:
    os.environ["LD_LIBRARY_PATH"] = _original_library_path
else:
    os.environ.pop("LD_LIBRARY_PATH", None)

# Releases are built by lethevimlet/lichii-bc250; this fork carries the sources and the plugin.
REPO = "lethevimlet/lichii-bc250"
USER = decky.DECKY_USER
HOME = decky.DECKY_USER_HOME
APP_DIR = os.path.join(HOME, "Applications/lichii-bc250")
CONTAINER = "lichii-bc250-runtime"
CONFIG_DIR = os.path.join(HOME, ".config/lichii-bc250")
GAMES_INI = os.path.join(CONFIG_DIR, "games")
SETTINGS = os.path.join(decky.DECKY_PLUGIN_SETTINGS_DIR, "settings.json")
ART_CACHE = os.path.join(decky.DECKY_PLUGIN_RUNTIME_DIR, "art")
EDEN = os.path.join(HOME, ".local/share/eden")
LOAD_DIR = os.path.join(EDEN, "load")
GAME_LIST_CACHE = os.path.join(HOME, ".cache/eden/game_list")
LOG_FILE = os.path.join(EDEN, "log/eden_log.txt")
# Present (holding the release tag) while a newer release is out: the launch wrapper says so once.
UPDATE_FLAG = os.path.join(CONFIG_DIR, "update-available")
# The BC-250 tuning the README recommends; each item is a file of ours, removed by Revert.
SYSCTL_CFG = {"swappiness": ("/etc/sysctl.d/99-bc250-swappiness.conf", "vm.swappiness", "10"),
              "compaction": ("/etc/sysctl.d/99-bc250-compaction.conf", "vm.compaction_proactiveness", "100"),
              "watermark": ("/etc/sysctl.d/99-bc250-watermark.conf", "vm.watermark_scale_factor", "300")}
ZRAM_CONF = "/etc/systemd/zram-generator.conf"
ZRAM_SIZE = "min(ram * 3 / 4, 16384)"
OOMD_CONF = "/etc/systemd/system/user@.service.d/99-bc250-oomd.conf"
TTM_PAGES = "3145728"
# Same argument, three ways depending on the system: kernel arguments on rpm-ostree (Bazzite) and
# limine (CachyOS), a grub snippet elsewhere (SteamOS).
KARG = "ttm.pages_limit"
GRUB_CFG = "/etc/default/grub.d/lichii-bc250.cfg"
LIMINE_CONF = "/etc/limine-entry-tool.d/lichii-bc250.conf"
# ROM files Eden takes as a game, and the game list's own metadata cache (icon jpeg, name).
ROMS = (".nup", ".nsp", ".nsz", ".xci", ".xcz", ".nca", ".nro", ".nso", ".kip", ".nx")
TID = re.compile(r"(?<![0-9A-Fa-f])([0-9A-Fa-f]{16})(?![0-9A-Fa-f])")
# Built-in add-ons the emulator applies by title id (patch_manager.cpp): listed here to be switched;
# their names are the emulator's.
BUILTIN = {
    "0400486024DEC000": ["Max Resolution (built-in)", "Texture Pool x2 (built-in)",
                         "FPS Unlock (built-in)", "Dynamic FPS by Dark (built-in)"],
}
# A game's system language, and the region it is valid in (Settings::Language / Settings::Region
# order; the emulator warns on pairs its locale blocklist refuses, e.g. French on the Americas).
LANG_REGION = {0: 0, 1: 1, 2: 2, 3: 2, 4: 2, 5: 2, 6: 4, 7: 5, 8: 2, 9: 2, 10: 2, 11: 6,
               12: 2, 13: 1, 14: 1, 15: 4, 16: 6, 17: 1, 18: 2, 19: 1}


def _ids():
    import pwd
    pw = pwd.getpwnam(USER)
    return pw.pw_uid, pw.pw_gid


def _etc_read_only():
    """Stock SteamOS mounts the root read-only (steamos-readonly enabled)."""
    if not _which("steamos-readonly"):
        return False
    code, out = _run("steamos-readonly", "status")
    return code == 0 and out.strip().startswith("enabled")


def _etc_writable(work):
    """Runs work() with /etc writable on SteamOS, then puts the root back as it was."""
    was_ro = _etc_read_only()
    if was_ro:
        _run("steamos-readonly", "disable")
    try:
        return work()
    finally:
        if was_ro:
            _run("steamos-readonly", "enable")


def _as_user(*cmd):
    """A command as the desktop user: distrobox keeps its containers (and podman store) per user,
    the decky service is root."""
    uid = _ids()[0]
    env = dict(os.environ, HOME=HOME, USER=USER, PATH=_PATH,
               XDG_RUNTIME_DIR=f"/run/user/{uid}", DBUS_SESSION_BUS_ADDRESS=f"unix:path=/run/user/{uid}/bus")
    runner = ["runuser", "-u", USER, "--"] if _which("runuser") else ["sudo", "-u", USER, "--"]
    try:
        p = subprocess.run(runner + list(cmd), capture_output=True, text=True, env=env)
    except FileNotFoundError as e:
        return -1, str(e)
    out = (p.stdout + p.stderr).strip()
    decky.logger.info("%s -> %d %s", " ".join(cmd), p.returncode, out[-500:])
    return p.returncode, out


def _chown(path):
    uid, gid = _ids()
    for root, dirs, files in os.walk(path):
        for name in dirs + files:
            os.lchown(os.path.join(root, name), uid, gid)
    os.lchown(path, uid, gid)


def _mkdir_user(path):
    os.makedirs(path, exist_ok=True)
    # Every level under the home belongs to the user, not root.
    uid, gid = _ids()
    p = path
    while p.startswith(HOME + "/"):
        os.lchown(p, uid, gid)
        p = os.path.dirname(p)


def _load():
    try:
        with open(SETTINGS) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def _save(s):
    os.makedirs(os.path.dirname(SETTINGS), exist_ok=True)
    tmp = SETTINGS + ".tmp"
    with open(tmp, "w") as f:
        json.dump(s, f, indent=1)
    os.replace(tmp, SETTINGS)


# Decky's service may run with a short PATH: the system's own tools are always reachable.
_PATH = os.environ.get("PATH", "") + ":/usr/bin:/usr/sbin:/bin:/sbin"


def _run(*cmd):
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, env=dict(os.environ, PATH=_PATH))
    except FileNotFoundError as e:
        decky.logger.error("%s: %s", " ".join(cmd), e)
        return -1, str(e)
    out = (p.stdout + p.stderr).strip()
    decky.logger.info("%s -> %d %s", " ".join(cmd), p.returncode, out[-500:])
    return p.returncode, out


def _which(name):
    return shutil.which(name, path=_PATH)


def _ssl_context():
    # Decky's bundled Python has no CA certificates of its own: the system's bundle.
    for ca in ("/etc/ssl/certs/ca-certificates.crt", "/etc/pki/tls/certs/ca-bundle.crt", "/etc/ssl/cert.pem"):
        if os.path.exists(ca):
            return ssl.create_default_context(cafile=ca)
    return ssl.create_default_context()


def _get(url, path=None):
    req = urllib.request.Request(url, headers={"User-Agent": "Lichii-BC250-Decky"})
    with urllib.request.urlopen(req, timeout=120, context=_ssl_context()) as r:
        if path is None:
            return r.read()
        with open(path, "wb") as f:
            shutil.copyfileobj(r, f)
    return None


def _read(path):
    try:
        with open(path) as f:
            return f.read().strip()
    except OSError:
        return ""


def _bc250():
    """The BC-250 (1002:13fe): where the tuning applies. Elsewhere the plugin still makes shortcuts."""
    for dev in glob.glob("/sys/class/drm/card*/device"):
        if _read(f"{dev}/vendor") == "0x1002" and _read(f"{dev}/device") == "0x13fe":
            return True
    return False


def _installed_tag():
    """The release tag of the installed package (VERSION's first line, the build hash is second)."""
    return (_read(os.path.join(APP_DIR, "lichii", "VERSION")).splitlines() or [""])[0]


def _game_running():
    return _run("pgrep", "-x", "eden-cli")[0] == 0


# --- tuning ---------------------------------------------------------------------------------------

def _rpm_ostree():
    return _which("rpm-ostree")


def _ostree_kargs(tool):
    code, out = _run(tool, "kargs")
    if code != 0:
        return {}
    return dict(a.split("=", 1) if "=" in a else (a, "") for a in out.split())


def _limine():
    return _which("limine-entry-tool") and _which("limine-update")


def _limine_kernel():
    return _read(f"/usr/lib/modules/{os.uname().release}/pkgbase")


def _limine_kargs():
    code, out = _run("limine-entry-tool", "--get-cmdline", _limine_kernel(), "--no-hooks")
    if code != 0 or not out:
        return None
    return dict(a.split("=", 1) if "=" in a else (a, "") for a in out.splitlines()[-1].split())


def _karg_method():
    """How kernel arguments are set here: rpm-ostree (Bazzite), limine (CachyOS), grub files
    (SteamOS), or not at all."""
    if _rpm_ostree():
        return "rpm-ostree"
    if re.search(r"^ID=\"?steamos\"?$", _read("/etc/os-release"), re.M):
        return "files"
    if _limine() and _limine_kernel():
        return "limine"
    return "unsupported"


def _karg_active():
    """The limit ttm runs with; a command line can hold the argument twice and the last one wins."""
    active = _read("/sys/module/ttm/parameters/pages_limit")
    if active in ("", "0"):
        m = re.findall(r"ttm\.pages_limit=(\d+)", _read("/proc/cmdline"))
        active = m[-1] if m else ""
    return active


def _karg_configured(method):
    if method == "rpm-ostree":
        return _ostree_kargs(_rpm_ostree()).get(KARG, "")
    if method == "limine":
        return (_limine_kargs() or {}).get(KARG, "")
    g = re.findall(r"ttm\.pages_limit=(\d+)",
                   " ".join(_read(p) for p in ("/etc/default/grub", GRUB_CFG)))
    return g[-1] if g else ""


def _sysctl_write():
    """Writes our three sysctl files (the persistent side); returns the paths left over."""
    left = []
    for key, (path, param, want) in SYSCTL_CFG.items():
        if _read("/proc/sys/" + param.replace(".", "/")) != want:
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "w") as f:
                f.write(f"{param} = {want}\n")
        left.append(path)
    return left


def _sysctl_remove():
    for path, _, _ in SYSCTL_CFG.values():
        if os.path.exists(path):
            os.remove(path)


def _sysctl_before(s):
    """What each memory setting was before the plugin: the value Restore puts back."""
    if s.get("sysctl_before") is None:
        s["sysctl_before"] = {param: _read("/proc/sys/" + param.replace(".", "/"))
                              for _, param, _ in SYSCTL_CFG.values()}
    return s["sysctl_before"]


def _tuning_status():
    items = []
    runtime = bool(_load().get("runtime_tuning"))
    for key, (path, param, want) in SYSCTL_CFG.items():
        active = _read("/proc/sys/" + param.replace(".", "/"))
        persistent = os.path.exists(path)
        items.append({"key": key, "label": param, "want": want, "active": active,
                      "configured": persistent, "method": "sysctl", "reboot": False,
                      "runtime": True, "on": (not persistent) if runtime else active == want})
    zram = os.path.exists(ZRAM_CONF) or bool(_which("zram-generator"))
    zram_line = next((l.split("=", 1)[-1].strip() for l in _read(ZRAM_CONF).splitlines()
                      if l.startswith("zram-size")), "")
    items.append({"key": "zram", "label": "zram size", "want": ZRAM_SIZE,
                  "active": zram_line, "configured": _load().get("zram_before") is not None,
                  "method": "zram" if zram else "unsupported", "reboot": True, "on": zram_line == ZRAM_SIZE})
    items.append({"key": "oomd", "label": "systemd-oomd guard", "want": "80% for 20 s",
                  "active": "80% for 20 s" if os.path.exists(OOMD_CONF) else "not set",
                  "configured": os.path.exists(OOMD_CONF),
                  "method": "oomd" if _which("oomctl") else "unsupported", "reboot": False,
                  "on": os.path.exists(OOMD_CONF)})
    method = _karg_method()
    active_ttm = _karg_active()
    items.append({"key": "ttm", "label": f"{KARG}=12 GiB", "want": TTM_PAGES, "active": active_ttm,
                  "configured": _karg_configured(method) == TTM_PAGES, "method": method, "reboot": True,
                  "on": active_ttm == TTM_PAGES})
    return items


def _gtt_apply(method, log):
    """The one kernel argument, by the way this system takes them; a value set otherwise is left."""
    if method == "unsupported":
        log.append(f"kernel arguments are not ours to set here: add {KARG}={TTM_PAGES} by hand")
        return True
    configured = _karg_configured(method)
    if configured == TTM_PAGES:
        return True
    if configured:
        log.append(f"{KARG}={configured} is already set: left as it is")
        return True
    if method == "rpm-ostree":
        code, out = _run(_rpm_ostree(), "kargs", f"--append-if-missing={KARG}={TTM_PAGES}")
        if code != 0:
            log.append(out[-300:])
            return False
        s = _load()
        s["ostree_kargs"] = sorted(set(s.get("ostree_kargs", [])) | {f"{KARG}={TTM_PAGES}"})
        _save(s)
        return True
    if method == "limine":
        before = _limine_kargs()
        if before is None:
            log.append("limine-entry-tool --get-cmdline failed")
            return False
        prev = _read(LIMINE_CONF) if os.path.exists(LIMINE_CONF) else None
        os.makedirs(os.path.dirname(LIMINE_CONF), exist_ok=True)
        with open(LIMINE_CONF, "w") as f:
            f.write("# Lichii BC-250 (Decky plugin): 12 GiB of GTT for big games.\n"
                    f'KERNEL_CMDLINE[default]+=" {KARG}={TTM_PAGES}"\n')

        def restore():
            if prev is None:
                os.remove(LIMINE_CONF)
            else:
                with open(LIMINE_CONF, "w") as f:
                    f.write(prev + "\n")
        after = _limine_kargs() or {}
        lost = [k for k in before if k not in after]
        if lost or KARG not in after:
            restore()
            log.append("limine-entry-tool would drop " + (" ".join(lost) or KARG) +
                       ": add the argument to KERNEL_CMDLINE in /etc/default/limine by hand")
            return False
        code, out = _run("limine-update")
        if code != 0:
            restore()
            log.append(out[-300:])
            return False
        return True

    def write():
        os.makedirs(os.path.dirname(GRUB_CFG), exist_ok=True)
        with open(GRUB_CFG, "w") as f:
            f.write("# Lichii BC-250 (Decky plugin): 12 GiB of GTT for big games.\n"
                    f'GRUB_CMDLINE_LINUX="${{GRUB_CMDLINE_LINUX}} {KARG}={TTM_PAGES}"\n')
        for tool in ("update-grub", "grub-mkconfig"):
            if _which(tool):
                code, out = _run(tool, "-o", "/boot/grub/grub.cfg") if tool == "grub-mkconfig" else _run(tool)
                if code != 0:
                    log.append(out[-300:])
                    return False
                return True
        log.append("no update-grub or grub-mkconfig: run it by hand")
        return False
    return _etc_writable(write)


def _tuning_apply():
    log = []
    ok = True
    reboot = False
    runtime = bool(_load().get("runtime_tuning"))
    s = _load()
    _sysctl_before(s)
    _save(s)

    def write_sysctls():
        if runtime:
            # Set at each game's start and put back at its end: no file of ours at boot.
            _sysctl_remove()
        else:
            _sysctl_write()
    try:
        _etc_writable(write_sysctls)
    except OSError as e:
        ok = False
        log.append(str(e))
    if runtime:
        log.append("memory settings: during games only")
    code, out = _run("sysctl", "--system")
    if code != 0:
        ok = False
        log.append(out[-300:])
    if os.path.exists(ZRAM_CONF):
        text = _read(ZRAM_CONF)
        m = re.search(r"^zram-size\s*=.*$", text, re.M)
        s = _load()
        if s.get("zram_before") is None:
            # "" says the line was ours: Revert removes it instead of putting a value back.
            s["zram_before"] = m.group(0) if m else ""
            _save(s)
        text = re.sub(r"^zram-size\s*=.*$", f"zram-size = {ZRAM_SIZE}", text, count=1, flags=re.M) \
            if m else text.rstrip("\n") + f"\nzram-size = {ZRAM_SIZE}\n"
        def write_zram():
            with open(ZRAM_CONF, "w") as f:
                f.write(text)
        try:
            _etc_writable(write_zram)
        except OSError as e:
            ok = False
            log.append(str(e))
        log.append("zram size: after a reboot")
        reboot = True
    else:
        log.append("no zram-generator.conf: zram size left as it is")
    if _which("oomctl"):
        def write_oomd():
            os.makedirs(os.path.dirname(OOMD_CONF), exist_ok=True)
            with open(OOMD_CONF, "w") as f:
                f.write("[Service]\nManagedOOMMemoryPressure=kill\nManagedOOMMemoryPressureLimit=80%\n"
                        "ManagedOOMMemoryPressureDurationSec=20s\n")
        try:
            _etc_writable(write_oomd)
        except OSError as e:
            ok = False
            log.append(str(e))
        code, out = _run("systemctl", "daemon-reload")
        if code != 0:
            ok = False
            log.append(out[-300:])
    else:
        log.append("systemd-oomd is not here: guard left out")
    if not _gtt_apply(_karg_method(), log):
        ok = False
    else:
        reboot = True
    if reboot:
        log.append("reboot to use the new kernel and zram settings")
    return ok, "\n".join(x for x in log if x)


def _tuning_revert():
    log = []
    s0 = _load()
    if s0.get("runtime_tuning"):
        log.append("memory settings: no longer only during games")

    def remove_sysctls():
        _sysctl_remove()
    try:
        _etc_writable(remove_sysctls)
    except OSError as e:
        log.append(str(e))
    code, out = _run("sysctl", "--system")
    if code != 0:
        log.append(out[-300:])
    s = _load()
    s.pop("runtime_tuning", None)
    s.pop("sysctl_before", None)
    if s.get("zram_before") is not None and os.path.exists(ZRAM_CONF):
        text = re.sub(r"^zram-size\s*=.*$", s["zram_before"], _read(ZRAM_CONF), count=1, flags=re.M)
        if s["zram_before"] == "":
            text = re.sub(r"^zram-size\s*=.*\n?", "", text, count=1, flags=re.M)
        with open(ZRAM_CONF, "w") as f:
            f.write(text)
        s.pop("zram_before", None)
    if os.path.exists(OOMD_CONF):
        try:
            _etc_writable(lambda: os.remove(OOMD_CONF))
        except OSError as e:
            log.append(str(e))
        _run("systemctl", "daemon-reload")
    method = _karg_method()
    if method == "rpm-ostree":
        for arg in s.get("ostree_kargs", []):
            code, out = _run(_rpm_ostree(), "kargs", f"--delete-if-present={arg}")
            if code != 0:
                log.append(out[-300:])
        s["ostree_kargs"] = []
    elif method == "limine" and os.path.exists(LIMINE_CONF):
        os.remove(LIMINE_CONF)
        code, out = _run("limine-update")
        if code != 0:
            log.append(out[-300:])
    elif os.path.exists(GRUB_CFG):
        try:
            _etc_writable(lambda: os.remove(GRUB_CFG))
        except OSError as e:
            log.append(str(e))
        if _which("update-grub"):
            _run("update-grub")
        elif _which("grub-mkconfig"):
            _run("grub-mkconfig", "-o", "/boot/grub/grub.cfg")
    _save(s)
    log.append("reboot to finish")
    return "\n".join(log)


def _refresh_wrapper():
    """Puts the plugin's launch wrapper in place again after a plugin update: the install's own
    values (emulator, GUI, native or container) are kept from the wrapper that is there."""
    wrapper = os.path.join(APP_DIR, "lichii-bc250")
    if not os.path.exists(wrapper) or not os.access(os.path.join(APP_DIR, "lichii/eden-cli"), os.X_OK):
        return False
    old = _read(wrapper)

    def value(name):
        m = re.search(rf'^{name}="([^"]*)"', old, re.M)
        return m.group(1) if m else ""
    text = _read(os.path.join(decky.DECKY_PLUGIN_DIR, "assets/launcher.sh"))
    text = (text.replace("__EDEN_EXEC__", value("EDEN_EXEC") or os.path.join(APP_DIR, "lichii/eden-cli"))
                .replace("__GUI_EXEC__", value("GUI_EXEC"))
                .replace("__INSTALL_MODE__", value("INSTALL_MODE") or "native")
                .replace("__CONTAINER__", value("CONTAINER")))
    tmp = wrapper + ".tmp"
    with open(tmp, "w") as f:
        f.write(text)
    os.chmod(tmp, 0o755)
    os.lchown(tmp, *_ids())
    os.replace(tmp, wrapper)   # atomic: a launch that starts meanwhile gets the old or the new one
    return True


def _runtime_tuning(on):
    """Memory settings during games only. Off they are files of ours and set now; on the files go,
    the live values come back to what they were before the plugin, and each game sets them for its
    own run (the launcher puts them back at its end). zram, oomd and GTT stay as they are: they are
    read at boot and cannot follow a game."""
    log = []
    s = _load()
    before = _sysctl_before(s)
    if on:
        def remove():
            _sysctl_remove()
        try:
            _etc_writable(remove)
        except OSError as e:
            log.append(str(e))
        for param, prev in before.items():
            if prev and _read("/proc/sys/" + param.replace(".", "/")) != prev:
                code, out = _run("sysctl", "-w", f"{param}={prev}")
                if code != 0:
                    log.append(f"{param}: {out[-200:]}")
        log.append("memory settings: during games only")
    else:
        def write():
            _sysctl_write()
        try:
            _etc_writable(write)
        except OSError as e:
            log.append(str(e))
        code, out = _run("sysctl", "--system")
        if code != 0:
            log.append(out[-300:])
        log.append("memory settings: set now and at boot")
    s["runtime_tuning"] = bool(on)
    _save(s)
    return "\n".join(x for x in log if x)


# --- games ----------------------------------------------------------------------------------------

def _clean_name(name):
    name = re.sub(r"\[[^]]*\]|\([^)]*\)", " ", name)
    return re.sub(r"\s+", " ", name.replace("_", " ")).strip()


def _tid_in(name):
    m = TID.search(name)
    return m.group(1).upper() if m else ""


def _size(path):
    try:
        st = os.stat(path)
    except OSError:
        return 0
    if os.path.isfile(path):
        return st.st_size
    cached = _sizes.get(path)
    if cached and cached[0] == st.st_mtime:
        return cached[1]
    code, out = _run("du", "-sb", path)
    size = int(out.split()[0]) if code == 0 and out else 0
    _sizes[path] = (st.st_mtime, size)
    return size


_sizes = {}


def _nup_meta(path):
    """A .nup's own metadata for its base package: title id, name, version, icon (the container's
    meta TLVs). None when the file is not one we can read."""
    try:
        with open(path, "rb") as f:
            superblock = f.read(0x80)
            if len(superblock) != 0x80 or superblock[:4] != b"NUP\x01":
                return None
            toc_offset, toc_size = struct.unpack_from("<QQ", superblock, 0x08)
            want = superblock[0x18:0x38]
            f.seek(toc_offset)
            toc = f.read(toc_size)
            if len(toc) != toc_size or hashlib.sha256(toc).digest() != want or len(toc) < 0x30:
                return None
            magic, count = struct.unpack_from("<II", toc, 0)
            if magic != 0x01434F54 or count == 0 or 0x30 + count * 0x40 > len(toc):
                return None
            records = [toc[0x30 + i * 0x40:0x30 + (i + 1) * 0x40] for i in range(count)]
            dlc = sum(1 for r in records if r[0x18] == 2)
            updates = [struct.unpack_from("<I", r, 0x14)[0] for r in records if r[0x18] == 1]

            def tid_of(rec):
                return struct.unpack_from("<Q", rec, 0)[0]
            # The base package, or a standalone update (flag 0x01): those carry the whole game and boot
            # alone (loader/nup.cpp); a plain update without a base next to it would not.
            rec = next((r for r in records if r[0x18] == 0 and tid_of(r)), None) or \
                  next((r for r in records if r[0x18] == 1 and r[0x19] & 1 and tid_of(r)), None)
            if rec is not None:
                tid = tid_of(rec)
                meta_offset, meta_size = struct.unpack_from("<QI", rec, 0x20)
                out = {"title_id": f"{tid:016X}", "version": "", "name": "", "icon": b"",
                       "dlc": dlc, "update": max(updates) if updates else ""}
                if meta_offset and meta_size and meta_offset + meta_size <= os.path.getsize(path):
                    f.seek(meta_offset)
                    block = f.read(meta_size)
                    pos = 0
                    while pos + 8 <= len(block):
                        typ, _reserved, size = struct.unpack_from("<HHI", block, pos)
                        pos += 8
                        if pos + size > len(block):
                            break
                        payload = block[pos:pos + size]
                        pos += size
                        if typ == 0x0003:
                            out["icon"] = payload
                        elif typ == 0x0004:
                            out["version"] = payload.decode("utf-8", "replace")
                        elif typ == 0x0005:
                            out["name"] = payload.decode("utf-8", "replace")
                        elif typ == 0x0009:  # localized titles: u8 lang, lang, u32 len, name
                            p = 0
                            while p < len(payload):
                                lang_len = payload[p]
                                lang = payload[p + 1:p + 1 + lang_len].decode("utf-8", "replace")
                                p += 1 + lang_len
                                if p + 4 > len(payload):
                                    break
                                (data_len,) = struct.unpack_from("<I", payload, p)
                                p += 4
                                if lang in ("en-US", "en-GB"):
                                    out["name"] = out["name"] or payload[p:p + data_len].decode("utf-8", "replace")
                                p += data_len
                return out
    except (OSError, struct.error):
        return None
    return None


def _nacp_name(path):
    """The application name of a control.nacp next to a loose dump: entry 0 (American English), or
    the first non-empty one. The entries use compressed data on some titles (titles_data_format at
    0x3215, raw deflate); the names of those are read from the decompressed entries."""
    try:
        with open(path, "rb") as f:
            data = f.read()
    except OSError:
        return ""
    if len(data) < 0x3216:
        return ""
    if data[0x3215] == 1:
        import zlib
        size = struct.unpack_from("<H", data, 0)[0]
        try:
            data = zlib.decompress(data[2:2 + size], -15)
        except zlib.error:
            return ""
    for i in range(16):
        start = i * 0x300
        if start + 0x200 > len(data):
            break
        name = data[start:start + 0x200].split(b"\x00", 1)[0].decode("utf-8", "replace").strip()
        if name:
            return name
    return ""


def _game_entries(folder):
    """Every entry of the games folder that is a game: a .nup, a ROM file, or a folder holding one
    (or a loose exefs dump). Folders first, so a game both packed and unpacked shows once."""
    try:
        entries = sorted(os.scandir(folder), key=lambda e: (not e.is_dir(), e.name))
    except OSError:
        return []
    out = []
    for e in entries:
        if e.name.startswith("."):
            continue
        if e.is_dir():
            try:
                names = os.listdir(e.path)
            except OSError:
                continue
            if "exefs" in names or any(n.lower().endswith(ROMS) for n in names):
                out.append(e.path)
        elif e.name.lower().endswith(ROMS):
            out.append(e.path)
    return out


def _rom_files(path):
    if os.path.isfile(path):
        return [path]
    try:
        return [os.path.join(path, n) for n in sorted(os.listdir(path))
                if n.lower().endswith(ROMS)]
    except OSError:
        return []


def _base_of(tid):
    """GetBaseTitleID: the low 13 bits are the program index, updates and DLC (common_funcs.h)."""
    return f"{int(tid, 16) & ~0x1FFF:016X}"


def _scan(folder):
    games = []
    seen = set()
    for path in _game_entries(folder):
        nup = _nup_meta(path) if path.lower().endswith(".nup") else None
        # The title id: the archive's own, or the one in the entry's or its ROMs' names.
        tid = nup["title_id"] if nup else _tid_in(os.path.basename(path))
        if not tid:
            for f in _rom_files(path):
                tid = _tid_in(os.path.basename(f))
                if tid:
                    break
        if not tid:
            continue
        if tid in seen:
            continue
        seen.add(tid)
        name = (nup or {}).get("name") or ""
        if not name:
            name = _read(os.path.join(GAME_LIST_CACHE, tid + ".appname.txt")).strip()
        if not name:
            for f in ["control.nacp"] + [n for n in (os.listdir(path) if os.path.isdir(path) else [])
                                         if n.lower().endswith(".nacp")]:
                p = os.path.join(path, f)
                if os.path.exists(p):
                    name = _nacp_name(p)
                    break
        if not name:
            name = _clean_name(os.path.basename(path).rsplit(".", 1)[0]) or tid
        # Add-ons: DLC and update packages of the archive, or files of the folder whose title id is
        # base+0x800 (update) or base+0x1000+n (DLC, GetAOCID).
        base = _base_of(tid)
        update_tid = f"{int(base, 16) + 0x800:016X}"
        dlc, update = (nup["dlc"] if nup else 0), (str(nup["update"]) if nup and nup["update"] else "")
        if nup and update:
            update = f"v{update}" if len(update) < 8 else update
        for f in _rom_files(path):
            ftid = _tid_in(os.path.basename(f))
            if ftid and _base_of(ftid) == base and ftid != tid:
                if ftid == update_tid:
                    update = update or _clean_name(os.path.basename(f).rsplit(".", 1)[0])
                else:
                    dlc += 1
        games.append({"title_id": tid, "name": re.sub(r"\s+", " ", name).strip(), "path": path,
                      "size": _size(path), "version": (nup or {}).get("version", ""),
                      "icon": _icon(path, tid, nup), "dlc": dlc, "update": update})
    return games


def _icon(path, tid, nup=None):
    """The shortcut's icon file: the game list's cached icon, the archive's, or a sidecar image."""
    cached = os.path.join(GAME_LIST_CACHE, tid + ".jpeg")
    if os.path.exists(cached):
        return cached
    if nup and nup.get("icon"):
        out = os.path.join(ART_CACHE, tid + "-icon.jpg")
        os.makedirs(ART_CACHE, exist_ok=True)
        with open(out, "wb") as f:
            f.write(nup["icon"])
        return out
    if os.path.isdir(path):
        names = sorted(os.listdir(path))
        for n in names:
            if n.startswith("icon_") or n.lower().endswith((".png", ".jpg", ".jpeg", ".bmp")):
                return os.path.join(path, n)
    return os.path.join(decky.DECKY_PLUGIN_DIR, "assets", "default-icon.png")


# --- per-game config ------------------------------------------------------------------------------

def _ini_sections(text):
    sections, cur = {}, None
    for line in text.splitlines():
        s = line.strip()
        if s.startswith("[") and s.endswith("]"):
            cur = s[1:-1]
            sections.setdefault(cur, [])
        elif cur is not None:
            sections[cur].append(line.rstrip())
    return sections


def _ini_set(sections, section, key, value):
    lines = [l for l in sections.setdefault(section, [])
             if not re.match(rf"^{re.escape(key)}(\\default)?=", l.strip())]
    lines += [f"{key}\\default=false", f"{key}={value}"]
    sections[section] = lines


def _ini_del(sections, section, key):
    """Removes a key of ours and its default flag; the value then comes from the emulator again."""
    sections[section] = [l for l in sections.get(section, [])
                         if not re.match(rf"^{re.escape(key)}(\\default)?=", l.strip())]


def _per_game_ini(tid):
    """The game's config: its own file when it exists (it holds the controller mapping the launcher
    copied into it), else game.ini, with the game's switches and disabled add-ons written in. None
    when there is no template (the emulator is not installed)."""
    path = os.path.join(GAMES_INI, tid + ".ini")
    source = path if os.path.exists(path) else os.path.join(APP_DIR, "game.ini")
    try:
        with open(source) as f:
            sections = _ini_sections(f.read())
    except OSError:
        return None
    s = _load()
    per = s.get("per_game", {}).get(tid, {})
    if "frame_gen" in per:
        _ini_set(sections, "Renderer", "frame_gen", "true" if per["frame_gen"] else "false")
    if "frame_gen_multiplier" in per:
        _ini_set(sections, "Renderer", "frame_gen_multiplier", str(per["frame_gen_multiplier"]))
    if "docked" in per:
        _ini_set(sections, "System", "use_docked_mode", "1" if per["docked"] else "0")
    language = per.get("language")
    if language is None or int(language) < 0:
        _ini_del(sections, "System", "language_index")
        _ini_del(sections, "System", "region_index")
    else:
        language = int(language)
        _ini_set(sections, "System", "language_index", str(language))
        if language in LANG_REGION:
            _ini_set(sections, "System", "region_index", str(LANG_REGION[language]))
        else:
            _ini_del(sections, "System", "region_index")
    disabled = s.get("disabled_addons", {}).get(tid, [])
    base = _base_of(tid)
    ids = [tid] + ([base] if base != tid else [])
    lines = [f"size={len(ids)}"]
    for i, t in enumerate(ids, 1):
        lines += [f"{i}\\title_id={int(t, 16)}", f"{i}\\disabled\\size={len(disabled)}"]
        # The emulator reads each name under its own key "d" (Config::ReadDisabledAddOnValues).
        lines += [f"{i}\\disabled\\{j}\\d={d}" for j, d in enumerate(disabled, 1)]
    sections["DisabledAddOns"] = lines
    _mkdir_user(GAMES_INI)
    out = [f"[{name}]\n" + "\n".join(lines) + "\n" for name, lines in sections.items()]
    tmp = path + ".tmp"
    if os.path.lexists(tmp):
        os.remove(tmp)
    # Root writes in the user's folder: never through a link put there.
    with os.fdopen(os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o644), "w") as f:
        f.write("\n".join(out))
    os.replace(tmp, path)
    os.lchown(path, *_ids())
    return path


def _mods(tid):
    """The game's mods and cheat files (load/<title id>/): a file cheat_*.txt or a folder."""
    folder = os.path.join(LOAD_DIR, tid)
    try:
        names = sorted(os.listdir(folder))
    except OSError:
        return []
    return [{"label": n, "kind": "mod"} for n in names
            if n.startswith("cheat_") or os.path.isdir(os.path.join(folder, n))]


def _addons(tid, game):
    disabled = set(_load().get("disabled_addons", {}).get(tid, []))
    rows = [{"label": n, "kind": "builtin", "on": n not in disabled} for n in BUILTIN.get(tid, [])]
    rows += [{"label": m["label"], "kind": "mod", "on": m["label"] not in disabled} for m in _mods(tid)]
    if game and game.get("dlc"):
        rows.append({"label": f"DLC ({game['dlc']})", "kind": "dlc", "on": "DLC" not in disabled})
    if game and game.get("update"):
        label = game["update"] if game["update"].lower().startswith("update") else f"Update {game['update']}"
        rows.append({"label": label, "kind": "update", "on": "Update" not in disabled})
    return rows


def _art(path):
    """The game's icon as base64 (a png/jpeg file)."""
    try:
        with open(path, "rb") as f:
            return base64.b64encode(f.read()).decode()
    except OSError:
        return ""


# --- release --------------------------------------------------------------------------------------

def _latest():
    rel = json.loads(_get(f"https://api.github.com/repos/{REPO}/releases/latest"))
    assets = {a["name"]: a["browser_download_url"] for a in rel.get("assets", [])}
    emu = next((u for n, u in assets.items() if n.endswith("-linux-x86_64.tar.gz")), "")
    return {"tag": rel.get("tag_name", ""), "emulator_url": emu,
            "sum_url": assets.get(next((n for n in assets if n.endswith(".tar.gz.sha256")), ""), ""),
            "plugin_url": next((u for n, u in assets.items() if n.endswith("-Decky.zip")), "")}


class Plugin:
    async def _main(self):
        decky.logger.info("Lichii BC-250 plugin %s", decky.DECKY_PLUGIN_VERSION)
        # The launch wrapper is the plugin's own file: put the current one in place (the values of
        # the install are kept), whatever way this build arrived.
        try:
            await asyncio.to_thread(_refresh_wrapper)
        except OSError as e:
            decky.logger.error("wrapper: %s", e)
        asyncio.get_event_loop().create_task(self._watch_updates())

    async def _unload(self):
        pass

    async def _watch_updates(self):
        while True:
            await self.latest_release()
            await asyncio.sleep(6 * 3600)

    # --- state ------------------------------------------------------------------------------------

    async def get_state(self):
        s = _load()
        folder = s.get("games_dir") or os.path.join(HOME, "Games")
        games = await asyncio.to_thread(_scan, folder)
        # A missing folder (a drive not mounted) has no games: their shortcuts go, and come back with it.
        try:
            folder_state = "ok" if os.listdir(folder) else "empty"
        except OSError:
            folder_state = "missing"
        known = s.get("games", {})
        installed = _installed_tag()
        if installed and s.get("emulator_tag") != installed:
            # The scan above can take seconds: save this key on what was read meanwhile.
            fresh = _load()
            fresh["emulator_tag"] = installed
            _save(fresh)
        for g in games:
            g.update({"appid": 0, **known.get(g["title_id"], {})})
            g["addons"] = _addons(g["title_id"], g)
            try:
                g["ini"] = await asyncio.to_thread(_per_game_ini, g["title_id"]) or ""
            except OSError as e:
                decky.logger.error("config of %s: %s", g["title_id"], e)
                g["ini"] = ""
        return {
            "app_dir": APP_DIR,
            "runner": os.path.join(APP_DIR, "lichii-bc250"),
            "emulator_version": s.get("emulator_tag", "") or _installed_tag(),
            "emulator_installed": os.access(os.path.join(APP_DIR, "lichii/eden-cli"), os.X_OK) and
                                  os.access(os.path.join(APP_DIR, "lichii-bc250"), os.X_OK),
            "plugin_version": decky.DECKY_PLUGIN_VERSION,
            "plugin_release": _read(os.path.join(decky.DECKY_PLUGIN_DIR, "RELEASE")),
            "home": HOME,
            "games_dir": folder,
            "games_dir_state": folder_state,
            "art_version": s.get("art_version", 1),
            "games": games,
            "gone": {k: v for k, v in known.items() if k not in {g["title_id"] for g in games} and v.get("appid")},
            "bc250": _bc250(),
            "tuning": _tuning_status(),
            "runtime_tuning": bool(s.get("runtime_tuning")),
            "game_running": _game_running(),
        }

    async def latest_release(self):
        try:
            rel = await asyncio.to_thread(_latest)
        except Exception as e:
            decky.logger.error("latest release: %s", e)
            return {"tag": "", "error": str(e)}
        current = _load().get("emulator_tag", "")
        try:
            if rel["emulator_url"] and current and rel["tag"] != current:
                _mkdir_user(CONFIG_DIR)
                with open(UPDATE_FLAG, "w") as f:
                    f.write(rel["tag"] + "\n")
                os.lchown(UPDATE_FLAG, *_ids())
            elif os.path.exists(UPDATE_FLAG):
                os.remove(UPDATE_FLAG)
        except OSError as e:
            decky.logger.error("update flag: %s", e)
        return rel

    # --- emulator ---------------------------------------------------------------------------------

    async def install_emulator(self, url, tag, sum_url=""):
        if _game_running():
            return {"ok": False, "log": "a game is running"}

        def work():
            _mkdir_user(APP_DIR)
            with tempfile.TemporaryDirectory(dir=APP_DIR) as tmp:
                archive = os.path.join(tmp, "lichii.tar.gz")
                _get(url, archive)
                if sum_url:
                    want = _get(sum_url).decode().split()[0]
                    with open(archive, "rb") as f:
                        have = hashlib.sha256(f.read()).hexdigest()
                    if have != want:
                        raise ValueError("checksum mismatch for the download")
                shutil.unpack_archive(archive, tmp, "gztar")
                src = next(os.path.join(tmp, d) for d in os.listdir(tmp)
                           if os.path.exists(os.path.join(tmp, d, "eden-cli")))
                with open(os.path.join(src, "VERSION"), "w") as f:
                    f.write(tag + "\n")
                old = APP_DIR + "/lichii.old"
                shutil.rmtree(old, ignore_errors=True)
                if os.path.exists(APP_DIR + "/lichii"):
                    os.rename(APP_DIR + "/lichii", old)
                os.rename(src, APP_DIR + "/lichii")
                shutil.rmtree(old, ignore_errors=True)
                _chown(APP_DIR + "/lichii")
            # The launcher and its config (see tools/bc250/bc250-install.sh). On Bazzite the package
            # runs in a small container (1.4 GB less memory held); without distrobox or when it fails,
            # the package runs natively.
            native = not _which("distrobox")
            if not native:
                # distrobox is per user: root's containers are invisible to the deck user Steam runs as.
                if CONTAINER not in _as_user("distrobox", "list")[1]:
                    code, out = _as_user("distrobox", "create", "-n", CONTAINER, "-i", "fedora:42", "-Y")
                    if code != 0:
                        decky.logger.error("container %s: %s", CONTAINER, out[-300:])
                        native = True
                if not native:
                    code, out = _as_user("distrobox", "enter", CONTAINER, "--", "sudo", "dnf", "-y", "install",
                                         "--skip-unavailable",
                                         "mesa-vulkan-drivers", "vulkan-loader", "libX11", "libX11-xcb", "libxcb",
                                         "libXext", "libXrandr", "libXcursor", "libXi", "libXfixes", "libXrender",
                                         "libXScrnSaver", "libxkbcommon", "wayland", "libdecor", "alsa-lib",
                                         "pulseaudio-libs", "pipewire-libs", "libusb1", "systemd-libs", "libdrm",
                                         "harfbuzz", "fribidi", "fontconfig", "freetype", "xcb-util-cursor",
                                         "xcb-util-wm", "xcb-util-image", "xcb-util-keysyms", "xcb-util-renderutil",
                                         "libxkbcommon-x11", "libglvnd-egl", "libglvnd-opengl", "mesa-libEGL",
                                         "mesa-libGL", "dbus-libs")
                    # The driver must resolve in the container the user enters, or the game cannot start.
                    if _as_user("distrobox", "enter", CONTAINER, "--", "test", "-f",
                                "/usr/share/vulkan/icd.d/radeon_icd.x86_64.json")[0] != 0:
                        decky.logger.error("container %s has no Vulkan driver: running natively", CONTAINER)
                        native = True
            wrapper = os.path.join(APP_DIR, "lichii-bc250")
            shutil.copyfile(os.path.join(decky.DECKY_PLUGIN_DIR, "assets/launcher.sh"), wrapper)
            with open(wrapper) as f:
                text = f.read()
            text = text.replace("__EDEN_EXEC__", os.path.join(APP_DIR, "lichii/eden-cli")) \
                       .replace("__GUI_EXEC__", os.path.join(APP_DIR, "lichii/usr/bin/lichii")
                                if os.access(os.path.join(APP_DIR, "lichii/usr/bin/lichii"), os.X_OK) else "") \
                       .replace("__INSTALL_MODE__", "native" if native else "release") \
                       .replace("__CONTAINER__", "" if native else CONTAINER)
            with open(wrapper, "w") as f:
                f.write(text)
            os.chmod(wrapper, 0o755)
            if not os.path.exists(os.path.join(APP_DIR, "game.ini")):
                shutil.copyfile(os.path.join(decky.DECKY_PLUGIN_DIR, "assets/game.ini"),
                                os.path.join(APP_DIR, "game.ini"))
            # A controller mapped in the GUI is copied into a game's config by the launcher with it.
            helper = os.path.join(APP_DIR, "lichii/tools/import_gui_controls.py")
            if os.path.exists(helper):
                shutil.copyfile(helper, os.path.join(APP_DIR, "import_gui_controls.py"))
            _chown(APP_DIR)
            if os.access(os.path.join(APP_DIR, "lichii/usr/bin/lichii"), os.X_OK):
                os.makedirs(os.path.join(HOME, ".local/share/applications"), exist_ok=True)
                with open(os.path.join(HOME, ".local/share/applications/lichii-bc250.desktop"), "w") as f:
                    f.write("[Desktop Entry]\nType=Application\nName=Lichii BC-250\n"
                            "Comment=Emulator settings and controller mapping (the Steam shortcut uses them)\n"
                            f"Exec={wrapper} --gui\nIcon=applications-games\n"
                            "Categories=Game;Emulator;\nTerminal=false\n")
                os.lchown(os.path.join(HOME, ".local/share/applications/lichii-bc250.desktop"), *_ids())
            s = _load()
            s["emulator_tag"] = tag
            _save(s)
            if os.path.exists(UPDATE_FLAG):
                os.remove(UPDATE_FLAG)
            return {"ok": True, "log": ""}
        try:
            return await asyncio.to_thread(work)
        except Exception as e:
            decky.logger.exception("install")
            return {"ok": False, "log": str(e)}

    async def install_plugin(self, url, tag):
        def work():
            with tempfile.TemporaryDirectory() as tmp:
                z = os.path.join(tmp, "plugin.zip")
                _get(url, z)
                try:
                    want = _get(url + ".sha256").decode().split()[0]
                    with open(z, "rb") as f:
                        have = hashlib.sha256(f.read()).hexdigest()
                    if have != want:
                        raise ValueError("checksum mismatch for the download")
                except Exception as e:
                    decky.logger.error("plugin checksum: %s", e)
                    if "checksum" in str(e):
                        raise
                with zipfile.ZipFile(z) as f:
                    f.extractall(tmp)
                src = next(os.path.join(tmp, d) for d in os.listdir(tmp)
                           if os.path.exists(os.path.join(tmp, d, "plugin.json")))
                with open(os.path.join(src, "RELEASE"), "w") as f:
                    f.write(tag + "\n")
                dst = decky.DECKY_PLUGIN_DIR
                old = dst + ".old"
                shutil.rmtree(old, ignore_errors=True)
                shutil.copytree(src, dst + ".new")
                os.rename(dst, old)
                os.rename(dst + ".new", dst)
                shutil.rmtree(old, ignore_errors=True)
            # The launch wrapper follows the plugin: a new one (runtime tuning) replaces the old.
            try:
                _refresh_wrapper()
            except OSError as e:
                decky.logger.error("wrapper: %s", e)
            return {"ok": True}
        try:
            r = await asyncio.to_thread(work)
        except Exception as e:
            decky.logger.exception("plugin update")
            return {"ok": False, "log": str(e)}
        # Restart as the user first (that is where Decky runs), the system unit after it.
        code, out = await asyncio.to_thread(_as_user, "systemctl", "--user", "restart", "plugin_loader")
        if code != 0:
            code, out = _run("systemctl", "restart", "plugin_loader")
        if code != 0:
            decky.logger.error("plugin restart: %s", out[-300:])
            return {"ok": False, "log": "updated, but plugin_loader did not restart: " + out[-300:]}
        return r

    # --- tuning -----------------------------------------------------------------------------------

    async def tuning_apply(self):
        if _game_running():
            return {"ok": False, "log": "a game is running"}
        ok, log = await asyncio.to_thread(_tuning_apply)
        return {"ok": ok, "log": log}

    async def tuning_revert(self):
        if _game_running():
            return {"ok": False, "log": "a game is running"}
        return {"ok": True, "log": await asyncio.to_thread(_tuning_revert)}

    async def set_runtime_tuning(self, on):
        """The three memory settings during games only (set at a game's start, put back at its end)."""
        return {"ok": True, "log": await asyncio.to_thread(_runtime_tuning, bool(on))}

    async def reboot(self):
        subprocess.Popen(["sh", "-c", "sleep 1; systemctl reboot"], start_new_session=True)

    # --- games ------------------------------------------------------------------------------------

    async def set_games_dir(self, path):
        s = _load()
        s["games_dir"] = path
        _save(s)

    async def set_art_version(self, version):
        s = _load()
        s["art_version"] = version
        _save(s)
        # The cache keeps one directory per version; the others are dead.
        try:
            for name in os.listdir(ART_CACHE):
                if re.fullmatch(r"[0-9A-Fa-f]{16}-v\d+", name) and not name.endswith(f"-v{version}"):
                    shutil.rmtree(os.path.join(ART_CACHE, name), ignore_errors=True)
        except OSError:
            pass

    async def set_game(self, title_id, appid, path=""):
        s = _load()
        games = s.setdefault("games", {})
        if appid:
            # shortcut_path: the game the shortcut starts; a game moved gets it again.
            games[title_id] = {"appid": appid, "shortcut_path": path}
        else:
            games.pop(title_id, None)
        _save(s)

    async def get_game(self, title_id):
        s = _load()
        games = await asyncio.to_thread(_scan, s.get("games_dir") or os.path.join(HOME, "Games"))
        g = next((g for g in games if g["title_id"] == title_id), None)
        if g is None:
            return None
        return {
            "title_id": title_id, "name": g["name"], "path": g["path"], "size": g["size"],
            "appid": s.get("games", {}).get(title_id, {}).get("appid", 0),
            "version": g["version"],
            "addons": _addons(title_id, g),
            "settings": s.get("per_game", {}).get(title_id, {}),
            "ini": _per_game_ini(title_id) or "",
            "mods_dir": os.path.join(LOAD_DIR, title_id),
            "log_file": LOG_FILE,
            "game_running": _game_running(),
        }

    async def set_addon(self, title_id, label, kind, on):
        s = _load()
        # The engine's keys, not the labels the page shows (a mod may be named "Update pack").
        if kind == "dlc":
            label = "DLC"
        elif kind == "update":
            label = "Update"
        entry = s.setdefault("disabled_addons", {}).setdefault(title_id, [])
        if on:
            entry[:] = [x for x in entry if x != label]
        elif label not in entry:
            entry.append(label)
        entry[:] = sorted(set(entry))
        if not entry:
            s["disabled_addons"].pop(title_id, None)
        _save(s)
        try:
            await asyncio.to_thread(_per_game_ini, title_id)
        except OSError as e:
            decky.logger.exception("per-game config")
            return {"ok": False, "log": str(e)}
        return {"ok": True}

    async def set_setting(self, title_id, key, value):
        """One of the game's own settings (frame_gen, frame_gen_multiplier, docked, language)."""
        if key not in ("frame_gen", "frame_gen_multiplier", "docked", "language"):
            return {"ok": False, "log": "not a setting of a game"}
        if key == "language" and not -1 <= int(value) < len(LANG_REGION):
            return {"ok": False, "log": "not a language"}
        s = _load()
        per = s.setdefault("per_game", {}).setdefault(title_id, {})
        per[key] = int(value) if key in ("frame_gen_multiplier", "language") else bool(value)
        _save(s)
        try:
            await asyncio.to_thread(_per_game_ini, title_id)
        except OSError as e:
            return {"ok": False, "log": str(e)}
        return {"ok": True}

    # Artwork made once per game (the frontend composes it) and kept: a shortcut added again reuses it.
    async def get_cached_art(self, title_id):
        if not re.fullmatch(r"[0-9A-Fa-f]{16}(-v\d+)?", title_id):
            return {}
        def work():
            out = {}
            for kind in ("capsule", "hero", "wide"):
                try:
                    with open(os.path.join(ART_CACHE, title_id, kind + ".png"), "rb") as f:
                        out[kind] = base64.b64encode(f.read()).decode()
                except OSError:
                    return {}
            return out
        return await asyncio.to_thread(work)

    async def save_art(self, title_id, kind, data):
        if not re.fullmatch(r"[0-9A-Fa-f]{16}(-v\d+)?", title_id) or kind not in ("capsule", "hero", "wide"):
            return
        def work():
            d = os.path.join(ART_CACHE, title_id)
            os.makedirs(d, exist_ok=True)
            with open(os.path.join(d, kind + ".png"), "wb") as f:
                f.write(base64.b64decode(data))
        await asyncio.to_thread(work)

    async def get_art(self, path):
        """The icon file as base64; a path outside our own folders is not read."""
        real = os.path.realpath(path)
        if not any(real == r or real.startswith(r + "/")
                   for r in (HOME, decky.DECKY_PLUGIN_DIR, decky.DECKY_PLUGIN_RUNTIME_DIR)):
            return {"icon": ""}
        return {"icon": await asyncio.to_thread(_art, real)}
