// Steam shortcuts for the games: made through SteamClient (only the frontend has it), with artwork
// composed from the game's own icon.
import { callable } from "@decky/api";

export interface Game {
  title_id: string;
  name: string;
  path: string;
  size: number;
  icon: string;
  shortcut_path?: string;
  appid: number;
  ini: string;
  dlc: number;
  update: string;
}

const getArt = callable<[path: string], { icon: string }>("get_art");
type Art = { capsule: string; hero: string; wide: string };
const getCachedArt = callable<[titleId: string], Partial<Art>>("get_cached_art");
const saveArt = callable<[titleId: string, kind: string, data: string], void>("save_art");
const setGame = callable<[titleId: string, appid: number, path?: string], void>("set_game");

const steam = () => (window as any).SteamClient;
const appStore = () => (window as any).appStore;
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

// PS5 games say (PS5) the same way: both can sit in one library and stay apart.
export const shortcutName = (g: Game) => `${g.name} (Switch 2)`;

// The wrapper takes the game's own config with -c when the plugin made one, then the usual
// fullscreen game path.
const launchOptions = (g: Game) =>
  `${g.ini ? `-c "${g.ini}" ` : ""}-f -g "${g.path}"`;

function exists(appid: number): boolean {
  return !!appid && !!appStore()?.GetAppOverviewByAppID(appid);
}

async function image(b64: string): Promise<HTMLImageElement | null> {
  if (!b64) return null;
  const img = new Image();
  img.src = `data:image/png;base64,${b64}`;
  try {
    await img.decode();
    return img;
  } catch {
    return null;
  }
}

// Draws `img` over the whole w x h canvas, cropping what does not fit (as CSS object-fit: cover).
function cover(ctx: CanvasRenderingContext2D, img: HTMLImageElement, w: number, h: number, pad = 0) {
  const s = Math.max((w + 2 * pad) / img.width, (h + 2 * pad) / img.height);
  const dw = img.width * s;
  const dh = img.height * s;
  ctx.drawImage(img, (w - dw) / 2, (h - dh) / 2, dw, dh);
}

// The game's icon on a blurred copy of itself: no game ships a picture here, so the icon is the
// picture.
function canvas(w: number, h: number, draw: (ctx: CanvasRenderingContext2D) => void): string {
  const c = document.createElement("canvas");
  c.width = w;
  c.height = h;
  draw(c.getContext("2d")!);
  return c.toDataURL("image/png").split(",")[1];
}

// Steam's custom artwork kinds: 0 capsule (600x900), 1 hero (1920x620), 3 wide capsule (920x430).
async function composeArt(g: Game): Promise<Art | null> {
  const art = await getArt(g.icon);
  const icon = await image(art.icon);
  if (!icon) return null;
  return {
    capsule: canvas(600, 900, (ctx) => {
      ctx.fillStyle = "#0e141b";
      ctx.fillRect(0, 0, 600, 900);
      ctx.filter = "blur(12px) brightness(0.85)";
      cover(ctx, icon, 600, 900, 24);
      ctx.filter = "none";
      ctx.drawImage(icon, 70, 220, 460, 460);
    }),
    hero: canvas(1920, 620, (ctx) => {
      ctx.fillStyle = "#0e141b";
      ctx.fillRect(0, 0, 1920, 620);
      ctx.filter = "blur(24px) brightness(0.8)";
      cover(ctx, icon, 1920, 620);
      ctx.filter = "none";
      const s = Math.min(480 / icon.width, 480 / icon.height);
      ctx.drawImage(icon, (1920 - icon.width * s) / 2, (620 - icon.height * s) / 2, icon.width * s, icon.height * s);
    }),
    wide: canvas(920, 430, (ctx) => {
      ctx.fillStyle = "#0e141b";
      ctx.fillRect(0, 0, 920, 430);
      ctx.filter = "blur(12px) brightness(0.85)";
      cover(ctx, icon, 920, 430, 24);
      ctx.filter = "none";
      ctx.drawImage(icon, 310, 65, 300, 300);
    }),
  };
}

// Raised when the artwork's look changes: shortcuts get it again, the cache keeps one per version.
export const ART_VERSION = 1;

async function setArtwork(appid: number, g: Game) {
  const key = `${g.title_id}-v${ART_VERSION}`;
  let art = (await getCachedArt(key)) as Art;
  if (!art.capsule) {
    const made = await composeArt(g);
    if (!made) return;
    art = made;
    for (const kind of ["capsule", "hero", "wide"] as const) await saveArt(key, kind, art[kind]);
  }
  await steam().Apps.SetCustomArtworkForApp(appid, art.capsule, "png", 0);
  await steam().Apps.SetCustomArtworkForApp(appid, art.hero, "png", 1);
  await steam().Apps.SetCustomArtworkForApp(appid, art.wide, "png", 3);
}

// A shortcut already in Steam with this name (one the settings lost, or made by hand): taken over
// instead of adding another.
function byName(name: string): number {
  const app = [...(appStore()?.allApps ?? [])].find((a: any) => a.app_type === 1073741824 && a.display_name === name);
  return app?.appid ?? 0;
}

// Adds or updates the shortcut of one game; returns its app id.
export async function syncGame(g: Game, runner: string, appDir: string, redoArt = false): Promise<number> {
  let appid = exists(g.appid) ? g.appid : byName(shortcutName(g));
  const fresh = !appid;
  if (fresh) {
    appid = await steam().Apps.AddShortcut(shortcutName(g), `"${runner}"`, "", "");
    await sleep(500);
  }
  steam().Apps.SetShortcutName(appid, shortcutName(g));
  steam().Apps.SetShortcutExe(appid, `"${runner}"`);
  steam().Apps.SetShortcutStartDir(appid, `"${appDir}/"`);
  steam().Apps.SetShortcutLaunchOptions(appid, launchOptions(g));
  steam().Apps.SetShortcutIcon(appid, g.icon);
  if (fresh || redoArt) await setArtwork(appid, g);
  await setGame(g.title_id, appid, g.path);
  return appid;
}

// Shortcuts of games that are no longer in the folder.
export async function removeGone(gone: Record<string, { appid: number }>) {
  for (const [titleId, { appid }] of Object.entries(gone)) {
    if (exists(appid)) steam().Apps.RemoveShortcut(appid);
    await setGame(titleId, 0);
  }
}

export async function syncAll(
  games: Game[],
  gone: Record<string, { appid: number }>,
  runner: string,
  appDir: string,
  redoArt = false,
) {
  // Two games of the same name would share one shortcut (Steam looks it up by name): the later
  // ones get the end of their title id, stably.
  const counts = new Map<string, number>();
  for (const g of games) {
    const n = (counts.get(g.name) ?? 0) + 1;
    counts.set(g.name, n);
    await syncGame(n > 1 ? { ...g, name: `${g.name} [${g.title_id.slice(-4)}]` } : g, runner, appDir, redoArt);
  }
  await removeGone(gone);
}

// True when a game has no shortcut yet, one was removed or the game moved: an automatic sync is
// worth it.
export function needsSync(games: Game[], gone: Record<string, { appid: number }>): boolean {
  return (
    Object.keys(gone).some((t) => exists(gone[t].appid)) ||
    games.some((g) => !exists(g.appid) || g.shortcut_path !== g.path)
  );
}
