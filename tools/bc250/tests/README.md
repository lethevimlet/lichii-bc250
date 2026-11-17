# BC-250 test harness and monitors (research tooling)

The scripts used to measure lichii-bc250 on an AMD BC-250 (Bazzite, Gaming Mode, Steam shortcut). They are kept
as they were used, for future development. They are not a supported tool: many are one-off sequences
(`seq*.sh`, `batch*.sh`) whose binary names and env switches belong to a past experiment.

## Setup

- Copy the folder to `~/oot-bc250-tests` on the box. The scripts expect that path.
- Paths come from `BC250_HOME`, falling back to `$HOME`.
- The account the game runs as comes from `BC250_USER`, falling back to `$USER`.
- Scripts that run as root need both set: `perfdwarf.sh`, `perfplaza.sh`, `memtrack*.sh`, `memacct*.sh`,
  `kx`-style sequences started with `sudo systemd-run`.
- Test binaries live in `~/Applications/eden-bins/<name>/eden-cli`. The file must keep the name `eden-cli`:
  the scripts find the game by that process name.
- Saves:
  - `saveguard.sh test|restore` swaps a frozen save set from `~/save-backups/<set>.tgz` in for a run and puts
    the player's saves back afterwards.
  - Route scripts load slot "Continue", so each set must hold the route's start point there.

## Main entry points

| Script | What it does |
|---|---|
| `routerun.sh <route> <label> <bin> [env]` | One route run: save set, launch through the Steam shortcut (`bc250-watch.py`), the 1 s memory sampler (`t1watch.sh`), the route, stop, restore. Waits while `PAUSED` exists. |
| `withtest.sh <cmd>` | Runs a test with the harness launcher in place and always puts the player's launcher back (also on TERM/INT). |
| `devpause.sh pause\|resume\|status` | Lets the player play in the middle of dev work: stops test units, restores launcher and saves, holds queued runs. |
| `oot-routelib.sh` + `oot-<route>.sh` | Ocarina routes: input through the debug server, marks into `long-<label>.txt`, screenshots into `shots/`. Routes: castle2, horse, kakariko, kokiri, idle. |
| `castlestats.py <label>` | Per-phase screen fps, repeated frames, worst gap and memory, from the log's `Screen:` lines and the t1 file. |
| `t1watch.sh <out>` / `t1wait.sh` | 1 s sampler: swap in/out, major faults, compaction, MemAvailable, GTT, the emulator's memory. |
| `liveev.py <state>` | Live session watcher: pauses > 1 s, errors, disk swap, PSI, 5-minute summaries. |
| `memtrack2.sh <label>` | Per-mapping private memory of the emulator during a session (root). |
| `perfdwarf.sh <label> <mark> <secs>` | DWARF perf profile of the GPU back thread when a route reaches a mark (root). |
| `tlx.sh` | Timeline captures (`EDEN_NX2_TIMELINE`) during the castle plaza spin, first and second visit. |
| `phasecause.py`, `phasework.py`, `bigframe.py`, `tcreason.py`, `tcchurn.py` | Analysis of stutter/texture-cache traces per route phase. |

Findings from these tools are in `docs/bc250-busy-scene-findings.md` and the CHANGELOG.
