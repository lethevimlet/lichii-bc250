# Busy scenes on the BC-250: what limits them (v19 research, 2026-11-17)

Research branch `v19` (not released). Goal: more fps in busy scenes, using the Castle Town plaza in Ocarina of Time
as the test. The first visit runs at 52-55 fps on screen; the second visit runs at 57-60.
Result: no change was worth shipping. This file records what was measured, what was tried, and what was left,
so the next attempt starts from here. All diagnostics below are env-gated and off by default.

## Where the GPU back thread's time goes (plaza)

- **Timeline** (`EDEN_NX2_GPU_PROFILE=1`, `EDEN_NX2_TIMELINE=<path>`, capture over 6 s of camera spin):
  - Both visits draw the same: ~154k draws per 6 s.
  - The first visit adds ~9 % of back-thread time. The extra is in the texture cache (+184 ms), configure
    (+172 ms), image views (+77 ms), texture uploads (+76 ms) and clears.
  - The front thread waits on the back thread on both visits.
- **perf** (DWARF call graphs, kernel frames resolved from `/proc/kallsyms`):
  - The emulator's own code is flat: no function takes more than ~4 %.
  - Kernel time: `mprotect` 4.9 %, GPU ioctls 3.1 %, TLB-shootdown IPIs ~1.6 %.

## Draws (fast/delta path)

- About 47 % of the ~45-60k draws/s take the delta path, at ~3 us each. Full draws cost ~9-14 us.
- The largest register break was vertex stream 0/15 stride/enable (~11k/s). Making it a draw parameter was
  verified safe, with 0 mismatches under `EDEN_NX2_FAST_DRAW_VERIFY`.
- It moved no draws, though: the same draws then broke on "vertex attribute types changed", which is a real
  pipeline change. The commit was reverted.
- The remaining breakers are real pipeline changes:
  - shader programs (regs 0x853/0x813/0x856);
  - attribute type classes;
  - texture-handle constant buffer writes.
- A delta draw reuses the previous pipeline without a lookup, so none of these can join the delta path safely.

## Page protection (mprotect)

- `EDEN_NX2_PROTECT_STATS=1` now splits calls by the cache that asked (`common/protect_tag.h`).
- Each line also reports the distinct pages the buffer cache protects, and why re-protected pages were not
  "hot" (EXP48).
- What it shows in the plaza:
  - ~3,000 protect and ~3,300 unprotect calls/s.
  - Almost all of them come from buffer-cache uploads re-protecting the same 500-700 pages.
  - 95 % of those pages were written by the GPU, and NoHot keeps such a page from ever being hot.
- `EDEN_NX2_HOT_NOHOT_EXPIRE=1` lets NoHot expire after a 128-frame epoch without GPU writes.
  - Calls dropped by only ~30 %, because the GPU keeps writing those pages.
  - It relaxes a safety rule (a hot page the GPU writes keeps its CPU-modified bit), so it stays off.
- Texture cache tracking adds only ~200 calls/s.

## Render-target churn

- The game moves ~20 render targets a frame within its memory pool:
  - 256x256 depth, ~205/s;
  - 960x540 targets;
  - 1920x1080 depth and colour.
- `DeleteSupersededImages` deletes the old ones two frames later. In the TC trace, `tcreason.py` shows them as
  reason "other".
- `EDEN_NX2_TC_CREATE_STATS=1` timing per create:
  - search 3-10 us;
  - host image 37-52 us;
  - joins/register 23-44 us.
- That is 3,500-6,000 creates per 10 s, ~3-5 % of the back thread in total.
- Reusing the Vulkan images of moved targets: `EDEN_NX2_IMAGE_RECYCLE_SMALL_MIB` (separate small pool, hashed
  keys, off by default).
  - It reused ~11k images with 24-59 MiB held.
  - The host-image part dropped only ~10 us per create, and fps stayed within noise.
- An earlier version that only lowered the size limit was worse:
  - The pool search was linear.
  - The 256 MiB held counted as device memory in use, so the texture cache collected harder and created more.
- Ceiling for any image-churn fix, including moving targets in place, is ~3-5 % of the back thread.

## Leads not followed

- **Moving superseded render targets in place.** Re-register an existing image at its new address instead of
  delete + create. It removes the whole create/delete cost (~3-5 %), at best ~1-2 fps, and touches the most
  delicate part of the texture cache.
- **Hyrule Field image creates.** Outside Castle Town only ~100 images are created per 10 s, but each takes
  ~1 ms in joins/register. That is ~1 % of the back thread, constantly.
- **Per-draw work in general.** The cost is spread thin: configure, binding stage buffers, uniform buffers,
  vertex buffers. A large gain needs a structural change (for example a cheaper full-draw path for pipelines
  that change), not a local fix.

## Test tooling (box, `~/oot-bc250-tests`)

- `routerun.sh castle2 <label> <bin> [env]` runs the castle route. `castlestats.py <label>` gives per-phase
  fps and repeats.
- Analysis scripts:
  - `tcreason.py` and `tcchurn.py`: texture churn, from runs with `EDEN_NX2_TC_TRACE=1`;
  - `phasework.py`: per-phase work;
  - `bigframe.py`: what made one frame long.
- Profiling:
  - `perfdwarf.sh <label> <mark> <secs>` (root) records a perf profile when the route reaches a mark.
  - `tlx.sh` captures timelines at the plaza spin. `tlself.py` (controller scratchpad) compares two of them.
- `devpause.sh pause|resume|status`: stops test units and restores the owner's launcher and saves, so the
  owner can play in the middle of dev work.
