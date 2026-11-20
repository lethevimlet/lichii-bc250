# Lichii BC-250 Decky plugin

Switch 2 games from Game Mode, the way PS5 games sit there in [KytyPS5-Native](https://github.com/superkeka/KytyPS5-Native):
each game in the folder becomes a Steam shortcut with its own artwork and a page in its library menu,
with its add-ons, its settings and what it is. The plugin also carries the README's board settings.

This plugin is adapted from KytyPS5-Native's decky-plugin by superkeka (GPL-2.0-only, like this
directory); the emulator side is Lichii's.

## What it does

- **The games folder.** Every `.nup`, `.nsp`, `.nsz`, `.xci`, `.xcz`, `.nca`, `.nro`, `.nso`, `.kip` or `.nx`, or the folder that holds one
  (a dump folder), is a game. Each gets a Steam shortcut named `<name> (Switch 2)`, started through
  the BC-250 launcher; the artwork is composed from the game's own icon (the NUP's, the game list's
  cached one, or a `control.nacp` / `icon` next to the dump). The shortcuts are made through
  SteamClient, so Steam keeps running (the CLI installer's VDF path is the one that needs it closed).
- **The game's page**, from its library menu (**Lichii BC-250...**): its add-ons (the emulator's
  built-in patches, its mods and `cheat_*` files in `~/.local/share/eden/load/<title id>`, its DLC and
  its update) and its settings (frame generation, its multiplier, docked mode, language). Each game's switches
  live in `~/.config/lichii-bc250/games/<title id>.ini`, from `game.ini` with the game's own lines.
- **Board tuning** (System tab, and the panel): the README steps — swappiness 10, compaction
  proactiveness 100, watermark 300, a large zram, the systemd-oomd guard, a 12 GiB GTT limit — with
  what runs now, Apply all and Revert all. **Memory settings during games only** sets the three
  memory ones at each game's start and puts the previous values back when it ends, so PS5 games keep
  their own; zram, oomd and GTT stay set. Each is a file of the plugin's; kernel arguments go through
  `rpm-ostree kargs`, a limine drop-in or a grub snippet, by system.
- **Updates.** The plugin installs the emulator from the latest release, checks the checksum, and
  updates itself from the release's plugin zip. Releases are built by
  [lethevimlet/lichii-bc250](https://github.com/lethevimlet/lichii-bc250).

It does not fetch keys, firmware or games, and installs nothing else. Only Install, Update, the
board settings and Reboot ask first; the add-on and per-game switches apply at once.

## Install

1. Install [Decky Loader](https://decky.xyz) and turn on its developer mode.
2. Download the latest `lichii-bc250-*-Decky.zip` from
   [Releases](https://github.com/lethevimlet/lichii-bc250/releases).
3. Decky settings > Developer > Install Plugin from ZIP File.
4. In the plugin: **Install** for the emulator, then pick the games folder in the Games tab.

In Decky's store, once published there. By hand, with Decky's developer mode:

```sh
cd decky-plugin
pnpm install
pnpm build
mkdir -p ~/homebrew/plugins/Lichii-BC250
cp -r dist assets ~/homebrew/plugins/Lichii-BC250/
cp plugin.json main.py ~/homebrew/plugins/Lichii-BC250/   # ~/.homebrew/plugins on newer Decky
sudo chown -R root:root ~/homebrew/plugins/Lichii-BC250
```

Then restart Decky (its developer menu reloads the plugins). In Game Mode the plugin's panel has
**Install** for the emulator; in Desktop Mode `tools/bc250/bc250-install.sh` does the same.

## Build and test

```sh
pnpm install
pnpm build          # dist/index.js, which Decky loads
```

`pnpm build` must stay clean (strict TypeScript). The backend is plain Python for Decky's runtime; its
NUP reader, game scan and per-game config are exercised by `test-main.py` and `test-state.py` in the
scratch directory of the session that wrote them (not shipped).

## Layout

| File | What it is |
|---|---|
| `main.py` | The root side: scan, per-game configs, tuning, installs. |
| `src/index.tsx` | The side panel: version, install, updates, links. |
| `src/page.tsx` | The Games and System tabs. |
| `src/game.tsx` | A game's page: add-ons, settings, about. |
| `src/shortcuts.ts` | Steam shortcuts and artwork (SteamClient is only in the frontend). |
| `src/menu.tsx` | The item in the game's library menu. |
| `assets/launcher.sh`, `assets/game.ini` | The launch wrapper and its config template, as `tools/bc250/bc250-install.sh` writes them. |
| `assets/default-icon.png` | Artwork for a game without an icon. |

## Notes

- A game's title id comes from its NUP metadata, its file names or its folder name; without one it is
  not listed. Dumps named without their title id need a `[<16 hex digits>]` tag in the folder or file
  name (the usual scene naming has it).
- The add-ons list is the emulator's: built-in patches by title id, the mods and cheat files of
  `load/<title id>`, DLC and update files that share the game's base title id. A game with none shows
  the mods folder to drop them in.
- Tuning is for the BC-250 board; elsewhere the shortcuts still work and the items show why not.
- `assets/launcher.sh` and `assets/game.ini` are copies of the installer's (its heredocs): change both
  together.
