// What the plugin's panel and its page share: the backend's calls, the state they show and the
// shortcut sync.
import { callable, toaster } from "@decky/api";
import { useEffect, useState } from "react";
import { setMenuGames } from "./menu";
import { ART_VERSION, Game, needsSync, syncAll } from "./shortcuts";

export interface TuningItem {
  key: string;
  label: string;
  want: string;
  active: string;
  configured: boolean;
  method: string;
  /** Whether the setting is read at boot. */
  reboot: boolean;
  /** Whether the setting can be set at a game's start and put back after it. */
  runtime?: boolean;
  on: boolean;
}

export interface State {
  app_dir: string;
  runner: string;
  emulator_version: string;
  emulator_installed: boolean;
  plugin_version: string;
  plugin_release: string;
  home: string;
  games_dir: string;
  games_dir_state: "ok" | "empty" | "missing";
  art_version: number;
  bc250: boolean;
  tuning: TuningItem[];
  /** The memory settings are set during games only. */
  runtime_tuning: boolean;
  games: Game[];
  gone: Record<string, { appid: number }>;
  game_running: boolean;
}

export interface Release {
  tag: string;
  emulator_url?: string;
  sum_url?: string;
  plugin_url?: string;
  error?: string;
}

export interface Result {
  ok: boolean;
  log?: string;
}

// An add-on of a game, switched on unless it is in the game's disabled list: a built-in patch, a
// mod or cheat file of the load folder, the game's DLC or its update.
export interface Addon {
  label: string;
  kind: "builtin" | "mod" | "dlc" | "update";
  on: boolean;
}

export interface GameSettings {
  frame_gen?: boolean;
  frame_gen_multiplier?: number;
  docked?: boolean;
  /** Settings::Language index; -1 is the emulator's own (English). */
  language?: number;
}

export interface GameInfo {
  title_id: string;
  name: string;
  path: string;
  size: number;
  // The game's Steam shortcut, 0 before it is made.
  appid: number;
  version: string;
  addons: Addon[];
  settings: GameSettings;
  mods_dir: string;
  log_file: string;
  ini: string;
}

const readState = callable<[], State>("get_state");
// Every read also tells the library's menu which shortcuts are the games'.
export async function getState(): Promise<State> {
  const s = await readState();
  setMenuGames(s.games);
  return s;
}
export const latestRelease = callable<[], Release>("latest_release");
export const installEmulator = callable<[url: string, tag: string, sumUrl: string], Result>("install_emulator");
const installPlugin = callable<[url: string, tag: string], Result>("install_plugin");
export const tuningApply = callable<[], Result>("tuning_apply");
export const tuningRevert = callable<[], Result>("tuning_revert");
export const setRuntimeTuning = callable<[on: boolean], Result>("set_runtime_tuning");
export const reboot = callable<[], void>("reboot");
export const setGamesDir = callable<[path: string], void>("set_games_dir");
const setArtVersion = callable<[version: number], void>("set_art_version");
export const getGame = callable<[titleId: string], GameInfo | null>("get_game");
export const setAddon = callable<[titleId: string, label: string, kind: string, on: boolean], Result>("set_addon");
export const setSetting = callable<[titleId: string, key: string, value: boolean | number], Result>("set_setting");

export const toast = (body: string, title = "Lichii BC-250") => toaster.toast({ title, body });
// Release tags without the project name: v20.
export const short = (tag: string) => tag.replace(/^lichii-bc250-/, "");
export const gigabytes = (bytes: number) => `${(bytes / 1e9).toFixed(1)} GB`;

// Decky's own installer (as its store): asks, swaps the files and reloads this plugin alone. Without
// it, the backend swaps them and restarts Decky.
export async function updatePlugin(release: Release) {
  const decky = (window as any).DeckyBackend;
  if (decky?.call) {
    await decky.call("utilities/install_plugin", release.plugin_url!, "Lichii-BC250", release.tag, "", 2);
    // This panel is the old version's: wait for the new one (the user confirms Decky's prompt first)
    // and have Decky show it in its place, as when the panel is opened.
    for (let i = 0; i < 60; i++) {
      await new Promise((r) => setTimeout(r, 2000));
      try {
        if ((await getState()).plugin_release === release.tag) {
          toast(`Plugin updated to ${short(release.tag)}`);
          const decky = (window as any).DeckyPluginLoader?.deckyState;
          if (decky?.publicState?.().activePlugin?.name === "Lichii-BC250") decky.setActivePlugin("Lichii-BC250");
          return;
        }
      } catch {
        // the backend restarts with the new version
      }
    }
    return;
  }
  const r = await installPlugin(release.plugin_url!, release.tag);
  toast(r.ok ? "Updated, Decky restarts" : r.log || "failed");
}

let syncRunning = false;
async function sync(s: State) {
  if (syncRunning) return;
  syncRunning = true;
  try {
    const redoArt = s.art_version !== ART_VERSION;
    await syncAll(s.games, s.gone, s.runner, s.app_dir, redoArt);
    if (redoArt) await setArtVersion(ART_VERSION);
  } catch (e) {
    console.error("Lichii BC-250 sync", e);
  }
  syncRunning = false;
}

const wantsSync = async (s: State) =>
  s.emulator_installed && (needsSync(s.games, s.gone) || s.art_version !== ART_VERSION);

// Also when nothing of the plugin is open: at start and every 10 minutes.
export async function autoSync() {
  const s = await getState();
  if (await wantsSync(s)) await sync(s);
}

// The plugin's state for a view: read when the view opens, and again after each action.
export function usePlugin() {
  const [state, setState] = useState<State | null>(null);
  const [release, setRelease] = useState<Release | null>(null);
  const [busy, setBusy] = useState("");
  const [syncing, setSyncing] = useState(false);

  // New games in the folder (and the folder itself) get their shortcuts on their own.
  const refresh = async () => {
    const s = await getState();
    setState(s);
    if ((await wantsSync(s)) && !syncRunning) {
      setSyncing(true);
      await sync(s);
      setSyncing(false);
      setState(await getState());
    }
  };
  useEffect(() => {
    refresh();
    latestRelease().then(setRelease);
  }, []);

  const run = async (what: string, work: () => Promise<void>) => {
    setBusy(what);
    try {
      await work();
    } catch (e) {
      toast(String(e), what);
    }
    setBusy("");
    try {
      await refresh();
    } catch (e) {
      toast(String(e), what);
    }
  };

  return { state, release, setRelease, busy, syncing, refresh, run };
}

export type PluginView = ReturnType<typeof usePlugin>;
