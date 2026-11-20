// A game's page, laid out as Steam's own page of a game: the artwork on top with the name over it,
// then what the emulator adds to the game in tabs: its add-ons, its settings, what it is.
import {
  DialogBody,
  DialogButton,
  DialogControlsSection,
  DropdownItem,
  Field,
  Focusable,
  GamepadButton,
  NavEntryPositionPreferences,
  ScrollPanel,
  ScrollPanelGroup,
  ToggleField,
  useParams,
} from "@decky/ui";
import { Dispatch, SetStateAction, useEffect, useRef, useState } from "react";
import { Addon, GameInfo, GameSettings, getGame, gigabytes, setAddon, setSetting, toast } from "./api";

// Sizes and colours are those of Steam's page of a game, so the two read as one.
const CSS = `
.lichii-game { position: relative; height: calc(100% - var(--gamepadui-current-footer-height, 42px)); overflow: hidden; background: #0e141b; }
.lichii-backdrop { position: absolute; inset: -12%; background-size: cover; background-position: center; filter: blur(64px) saturate(1.5); }
.lichii-backdrop::after { content: ""; position: absolute; inset: 0; background: rgba(14,20,27,0.8); }
.lichii-scroll { position: relative; height: 100%; }
.lichii-hero { position: relative; height: 38vh; min-height: 220px; background-size: cover; background-position: center 22%; background-color: #17202b; }
.lichii-hero::after { content: ""; position: absolute; inset: 0; background: linear-gradient(to bottom, rgba(14,20,27,0.62) 0, rgba(14,20,27,0) 26%, rgba(14,20,27,0) 44%, rgba(14,20,27,0.8) 100%); }
.lichii-hero-text { position: absolute; left: 2.8vw; right: 2.8vw; bottom: 18px; z-index: 1; }
.lichii-title { font-size: 40px; font-weight: 700; line-height: 1.1; color: #fff; text-shadow: 0 2px 14px rgba(0,0,0,0.65); }
.lichii-chips { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 12px; }
.lichii-chip { padding: 4px 12px; border-radius: 64px; background: rgba(255,255,255,0.16); color: #fff; font-size: 12px; font-weight: 700; letter-spacing: 0.5px; }
.lichii-tabs { display: flex; justify-content: center; gap: 2px; padding: 16px 0 12px; }
.lichii-pill { padding: 6px 16px; border-radius: 64px; color: #dcdedf; font-size: 12px; font-weight: 700; letter-spacing: 0.5px; text-transform: uppercase; white-space: nowrap; }
.lichii-pill.lichii-on { background: rgba(255,255,255,0.15); color: #fff; }
.lichii-pill.lichii-focus { background: #fff; color: #0e141b; }
.lichii-pill span { margin-left: 8px; opacity: 0.6; }
.lichii-body { padding: 0 2.8vw 2.5em; }
`;

type TabId = "addons" | "settings" | "about";
const TABS: TabId[] = ["addons", "settings", "about"];
// Frame generation multipliers the emulator takes (frame_gen_multiplier).
const MULTIPLIERS = [2, 3, 4];
// The game's system language (Settings::Language order) and the region the emulator pairs with it.
// -1 leaves the emulator's own language (English).
const LANGUAGES = [
  { data: -1, label: "Emulator default (English)" },
  { data: 2, label: "Français" },
  { data: 1, label: "English (US)" },
  { data: 12, label: "English (UK)" },
  { data: 3, label: "Deutsch" },
  { data: 4, label: "Italiano" },
  { data: 5, label: "Español" },
  { data: 14, label: "Español (Latinoamérica)" },
  { data: 8, label: "Nederlands" },
  { data: 9, label: "Português" },
  { data: 17, label: "Português (Brasil)" },
  { data: 10, label: "Русский" },
  { data: 18, label: "Polski" },
  { data: 0, label: "日本語" },
  { data: 6, label: "中文" },
  { data: 7, label: "한국어" },
  { data: 19, label: "ไทย" },
];

const steamStore = () => (window as any).appStore;
// The game's Steam shortcut, as Steam knows it.
function shortcut(appid: number): any {
  try {
    return (appid && steamStore()?.GetAppOverviewByAppID(appid)) || null;
  } catch {
    return null;
  }
}
// The artwork the shortcut got from the game (its icon under the title), as Steam serves it.
function heroOf(app: any): string {
  try {
    const url = app ? steamStore().GetCustomHeroImageURLs(app)?.[0] : "";
    return url ? (url.startsWith("/") ? `https://steamloopback.host${url}` : url) : "";
  } catch {
    return "";
  }
}
const Scroll = ScrollPanel as any;
const ScrollGroup = ScrollPanelGroup as any;

export function GamePage() {
  const { titleId } = useParams<{ titleId: string }>();
  const [game, setGame] = useState<GameInfo | null | undefined>(undefined);
  const [tab, setTab] = useState<TabId | undefined>(undefined);
  const pills = useRef<Partial<Record<TabId, HTMLDivElement | null>>>({});
  // Set once the user has picked a tab: the page does not pick for them after that.
  const picked = useRef(false);

  useEffect(() => {
    let open = true;
    const load = async () => {
      const g = await getGame(titleId);
      if (!open) return;
      setGame(g);
      if (g) setTab((t) => t ?? "addons");
    };
    load();
    return () => {
      open = false;
    };
  }, [titleId]);

  if (!game)
    return (
      <div className="lichii-game">
        <style>{CSS}</style>
        <div className="lichii-body" style={{ paddingTop: "calc(var(--basicui-header-height, 40px) + 12px)" }}>
          <DialogBody>
            {game === undefined ? (
              <Field label="Loading..." />
            ) : (
              <Field label="This game is not in the games folder any more" description={titleId} focusable />
            )}
          </DialogBody>
        </div>
      </div>
    );

  const app = shortcut(game.appid);
  const hero = heroOf(app);
  const addonsOn = game.addons.filter((a) => a.on).length;
  const shown = tab ?? "addons";
  const titles: Record<TabId, [string, string]> = {
    addons: ["Add-ons", game.addons.length ? `${addonsOn}/${game.addons.length}` : ""],
    settings: ["Settings", ""],
    about: ["About", ""],
  };

  // With a bumper the focus goes to the tab's name: what it was on is gone with the tab left.
  const pick = (id: TabId) => {
    picked.current = true;
    setTab(id);
  };
  const step = (by: number) => {
    const next = TABS[(TABS.indexOf(shown) + by + TABS.length) % TABS.length];
    pick(next);
    requestAnimationFrame(() => pills.current[next]?.focus());
  };

  return (
    <Focusable
      className="lichii-game"
      onButtonDown={(e) => {
        if (e.detail.button === GamepadButton.BUMPER_LEFT) step(-1);
        if (e.detail.button === GamepadButton.BUMPER_RIGHT) step(1);
      }}
      actionDescriptionMap={{ [GamepadButton.BUMPER_LEFT]: "Previous tab", [GamepadButton.BUMPER_RIGHT]: "Next tab" }}
    >
      <style>{CSS}</style>
      {hero && <div className="lichii-backdrop" style={{ backgroundImage: `url("${hero}")` }} />}
      <ScrollGroup focusable={false} className="lichii-scroll">
        <Scroll>
          <div className="lichii-hero" style={hero ? { backgroundImage: `url("${hero}")` } : undefined}>
            <div className="lichii-hero-text">
              <div className="lichii-title">{game.name}</div>
              <div className="lichii-chips">
                <span className="lichii-chip">{game.title_id}</span>
                {game.version && <span className="lichii-chip">{game.version}</span>}
                <span className="lichii-chip">{gigabytes(game.size)}</span>
              </div>
            </div>
          </div>

          {/* The row is entered at the tab that is open, and moving along it opens the next. */}
          <Focusable
            className="lichii-tabs"
            flow-children="horizontal"
            navEntryPreferPosition={NavEntryPositionPreferences.PREFERRED_CHILD}
          >
            {TABS.map((id) => (
              <Focusable
                key={id}
                ref={(el) => {
                  pills.current[id] = el;
                }}
                className={`lichii-pill${shown === id ? " lichii-on" : ""}`}
                focusClassName="lichii-focus"
                noFocusRing
                preferredFocus={shown === id}
                onActivate={() => pick(id)}
                onClick={() => pick(id)}
                onGamepadFocus={() => pick(id)}
              >
                {titles[id][0]}
                {titles[id][1] && <span>{titles[id][1]}</span>}
              </Focusable>
            ))}
          </Focusable>

          <div className="lichii-body">
            <DialogBody>
              {shown === "addons" && <AddonsTab game={game} setGame={setGame} />}
              {shown === "settings" && <SettingsTab game={game} setGame={setGame} />}
              {shown === "about" && <AboutTab game={game} app={app} />}
            </DialogBody>
          </div>
        </Scroll>
      </ScrollGroup>
    </Focusable>
  );
}

// A row with its action on a button at the right.
function Action(props: { label: string; description?: string; button: string; disabled?: boolean; onClick: () => void }) {
  return (
    <Field label={props.label} description={props.description} childrenContainerWidth="fixed">
      <DialogButton disabled={props.disabled} onClick={props.onClick} style={{ minWidth: "11em" }}>
        {props.button}
      </DialogButton>
    </Field>
  );
}

// What the emulator adds to a game: its built-in patches, the mods and cheat files of its load
// folder, its DLC and its update. Off is a name in the game's disabled list (the config's
// [DisabledAddOns] section).
const KIND_TEXT: Record<Addon["kind"], string> = {
  builtin: "Built into the emulator",
  mod: "Mod or cheat file",
  dlc: "The game's add-on content",
  update: "The game's update",
};

function AddonsTab(props: { game: GameInfo; setGame: Dispatch<SetStateAction<GameInfo | null | undefined>> }) {
  const { game, setGame } = props;
  const change = async (a: Addon, on: boolean) => {
    setGame((g) => g && { ...g, addons: g.addons.map((x) => (x.label === a.label ? { ...x, on } : x)) });
    const r = await setAddon(game.title_id, a.label, a.kind, on);
    if (!r.ok) {
      toast(r.log || "failed", game.name);
      setGame(await getGame(game.title_id));
    }
  };
  const on = game.addons.filter((a) => a.on).length;
  const allOff = async () => {
    for (const a of game.addons.filter((x) => x.on)) await change(a, false);
  };
  return (
    <DialogControlsSection>
      {game.addons.length ? (
        <>
          <Action label={`${on} of ${game.addons.length} on`} button="All off" disabled={!on} onClick={allOff} />
          <Field
            label="Add-ons the game can have"
            description={
              "All on to begin with; switch off the ones it should not have. Applies from the game's next start. " +
              `The mods and cheat files are in ${game.mods_dir}`
            }
            focusable
          />
        </>
      ) : (
        <Field
          label="None found"
          description={`Built-in patches, mods and cheat files (in ${game.mods_dir}) and DLC files in the game folder show here`}
          focusable
        />
      )}
      {game.addons.map((a) => (
        <ToggleField
          key={a.label + a.kind}
          label={a.label}
          description={KIND_TEXT[a.kind]}
          checked={a.on}
          onChange={(value) => change(a, value)}
        />
      ))}
    </DialogControlsSection>
  );
}

function SettingsTab(props: { game: GameInfo; setGame: Dispatch<SetStateAction<GameInfo | null | undefined>> }) {
  const { game, setGame } = props;
  const settings: GameSettings = game.settings ?? {};
  const change = async (key: keyof GameSettings, value: boolean | number) => {
    setGame((g) => g && { ...g, settings: { ...(g.settings ?? {}), [key]: value } });
    const r = await setSetting(game.title_id, key, value);
    if (!r.ok) {
      toast(r.log || "failed", game.name);
      setGame(await getGame(game.title_id));
    }
  };
  return (
    <>
      <DialogControlsSection>
        <ToggleField
          label="Frame generation"
          description={
            "One generated frame between every two game frames: about 60 fps on screen from a ~30 fps game. " +
            "Off gives the game's own rate"
          }
          checked={settings.frame_gen ?? true}
          onChange={(value) => change("frame_gen", value)}
        />
        <DropdownItem
          label="Frame generation multiplier"
          description="2 is the measured setting. 3 and 4 add frames but lower the game's own rate"
          rgOptions={MULTIPLIERS.map((n) => ({ data: n, label: `${n}×` }))}
          selectedOption={settings.frame_gen_multiplier ?? 2}
          onChange={(option) => change("frame_gen_multiplier", option.data)}
        />
      </DialogControlsSection>
      <DialogControlsSection>
        <ToggleField
          label="Docked mode"
          description="The game renders for the TV (docked); off reports the handheld display"
          checked={settings.docked ?? false}
          onChange={(value) => change("docked", value)}
        />
        <DropdownItem
          label="Language"
          description={
            "The console language the game reads. A game without that language stays in English. " +
            "Applies from the game's next start"
          }
          rgOptions={LANGUAGES}
          selectedOption={settings.language ?? -1}
          onChange={(option) => change("language", option.data)}
        />
      </DialogControlsSection>
    </>
  );
}

function AboutTab({ game, app }: { game: GameInfo; app: any }) {
  return (
    <DialogControlsSection>
      <Field label="Title ID" focusable>
        {game.title_id}
      </Field>
      {game.version && (
        <Field label="Version" focusable>
          {game.version}
        </Field>
      )}
      <Field label="Size" description={game.path} focusable>
        {gigabytes(game.size)}
      </Field>
      <Field label="Steam shortcut" focusable>
        {app ? app.display_name : "Not made yet"}
      </Field>
      <Field label="Mods and cheats" description={game.mods_dir} focusable />
      <Field label="Log of the last start" description={game.log_file} focusable />
    </DialogControlsSection>
  );
}
