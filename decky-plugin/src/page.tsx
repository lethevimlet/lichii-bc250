// The plugin's own page: tabs for the games and the BC-250 tuning. Each game has a page of its own
// (game.tsx); the system side (version, updates) is in the side panel.
import {
  DialogBody,
  DialogButton,
  DialogControlsSection,
  DialogControlsSectionHeader,
  Field,
  Tabs,
  ToggleField,
  useParams,
} from "@decky/ui";
import { openFilePicker } from "@decky/api";
import { ReactNode, useState } from "react";
import { FaChevronRight } from "react-icons/fa";
import {
  PluginView,
  State,
  gigabytes,
  reboot,
  setGamesDir,
  setRuntimeTuning,
  toast,
  tuningApply,
  tuningRevert,
  usePlugin,
} from "./api";
import { openGame } from "./routes";

// Under Steam's header, by the size Steam sets for it. A page that scrolls by itself also ends above
// Steam's footer (the button hints): a row under it could not be scrolled into view. Tabs leave that
// room on their own.
const Screen = ({ children, tabs }: { children: ReactNode; tabs?: boolean }) => (
  <div
    style={{
      marginTop: "var(--basicui-header-height, 40px)",
      height: tabs
        ? "calc(100% - var(--basicui-header-height, 40px))"
        : "calc(100% - var(--basicui-header-height, 40px) - var(--gamepadui-current-footer-height, 42px))",
    }}
  >
    {children}
  </div>
);
const Scroll = ({ children }: { children: ReactNode }) => (
  <div style={{ height: "100%", overflowY: "auto", padding: "0 2.8vw 2em", boxSizing: "border-box" }}>
    <DialogBody>{children}</DialogBody>
  </div>
);

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

function GamesTab({ view, state }: { view: PluginView; state: State }) {
  const total = state.games.reduce((sum, g) => sum + g.size, 0);
  return (
    <Scroll>
      <DialogControlsSection>
        <DialogControlsSectionHeader>
          {view.syncing
            ? "Adding to Steam..."
            : state.games.length
              ? `${state.games.length} ${state.games.length === 1 ? "game" : "games"}, ${gigabytes(total)}`
              : "Games"}
        </DialogControlsSectionHeader>
        {!state.emulator_installed && <Field label="Install Lichii BC-250 first" description="In the plugin's side panel" focusable />}
        {state.games.map((g) => (
          <Field
            key={g.title_id}
            label={g.name}
            description={
              `${g.title_id} · ${gigabytes(g.size)}` +
              (g.dlc ? ` · ${g.dlc} ${g.dlc === 1 ? "add-on" : "add-ons"}` : "") +
              (g.update ? " · update" : "")
            }
            focusable
            highlightOnFocus
            onActivate={() => openGame(g.title_id)}
            onClick={() => openGame(g.title_id)}
          >
            <FaChevronRight style={{ opacity: 0.5 }} />
          </Field>
        ))}
        {!state.games.length && (
          <Field
            label={state.games_dir_state === "missing" ? "Games folder not found" : "No games in the folder"}
            description="A game is a folder with a .nsp, .xci or .nup in it, or one of those files"
            focusable
          />
        )}
      </DialogControlsSection>
      <DialogControlsSection>
        <DialogControlsSectionHeader>Games folder</DialogControlsSectionHeader>
        <Action
          label={state.games_dir}
          description="Games in it get their Steam shortcuts on their own"
          button="Change"
          disabled={!!view.busy}
          onClick={async () => {
            const start = state.games_dir_state === "missing" ? state.home : state.games_dir;
            try {
              const r = await openFilePicker(1 as any, start, false, true);
              await setGamesDir(r.realpath || r.path);
            } catch {
              return; // closed without a choice
            }
            await view.refresh();
          }}
        />
      </DialogControlsSection>
    </Scroll>
  );
}

// The BC-250 steps of the README, the ones that are not in a game's settings: memory, swap and the
// GPU's page limit. Each shows what runs now; Apply sets all of them, Revert removes only ours.
function SystemTab({ view, state }: { view: PluginView; state: State }) {
  const { busy, run } = view;
  const pending = state.tuning.some((it) => it.configured && !it.on && it.reboot !== false);
  const off = state.tuning.filter((it) => !it.on && it.method !== "unsupported");
  const text = (it: (typeof state.tuning)[number]) =>
    it.method === "unsupported"
      ? "not supported here"
      : it.runtime && state.runtime_tuning
        ? "during games"
        : it.on
          ? "on"
          : it.configured
            ? "after reboot"
            : `set to ${it.want}`;
  return (
    <Scroll>
      {!state.bc250 && (
        <DialogControlsSection>
          <Field label="Not a BC-250" description="The tuning is for the BC-250 board; shortcuts still work" focusable />
        </DialogControlsSection>
      )}
      <DialogControlsSection>
        <DialogControlsSectionHeader>Tuning</DialogControlsSectionHeader>
        <Field
          label="The README's board settings"
          description={
            "Swappiness, compaction and the memory watermark, a larger zram, the systemd-oomd guard and a " +
            "12 GiB GTT limit: what the measured performance assumes. Each is a file of ours; the emulator " +
            "and the system stay as they are."
          }
          focusable
        />
        <ToggleField
          label="Memory settings during games only"
          description={
            "Swappiness, compaction and the watermark are set when a game starts and put back when it ends, " +
            "so the PS5 side keeps its own. zram, oomd and the GTT limit stay on: they are read at boot"
          }
          checked={state.runtime_tuning}
          disabled={!!busy || state.game_running}
          onChange={(on) =>
            run("Runtime tuning", async () => {
              const r = await setRuntimeTuning(on);
              toast(r.log || (on ? "Set during games" : "Set now and at boot"));
            })
          }
        />
        {state.tuning.map((it) => (
          <Field key={it.key} label={it.label} description={text(it)} focusable>
            {it.active && it.method !== "unsupported" ? String(it.active).slice(0, 30) : ""}
          </Field>
        ))}
        <Action
          label={off.length ? `${off.length} ${off.length === 1 ? "setting is" : "settings are"} off` : "Every setting is on"}
          description={
            state.runtime_tuning
              ? "The memory settings are left out here: they are set at each game's start"
              : "Takes effect after a reboot where it needs one; a game must be closed"
          }
          button={busy === "Tuning" ? "Applying..." : "Apply all"}
          disabled={!!busy || !off.length}
          onClick={() =>
            run("Tuning", async () => {
              const r = await tuningApply();
              toast(r.ok ? r.log || "Applied" : r.log || "failed");
            })
          }
        />
        {(state.tuning.some((it) => it.configured) || state.runtime_tuning) && (
          <Action
            label="Revert"
            description={
              state.runtime_tuning
                ? "Puts the memory settings back and removes the files this plugin made (only those)"
                : "Removes the files this plugin made (only those)"
            }
            button={busy === "Revert" ? "Reverting..." : "Revert all"}
            disabled={!!busy}
            onClick={() =>
              run("Revert", async () => {
                const r = await tuningRevert();
                toast(r.log || "Reverted");
              })
            }
          />
        )}
        {pending && (
          <Action
            label="Reboot to apply"
            description="The kernel and zram settings are read at boot"
            button="Reboot"
            disabled={!!busy || state.game_running}
            onClick={() => reboot()}
          />
        )}
      </DialogControlsSection>
    </Scroll>
  );
}

export function Page() {
  const view = usePlugin();
  const asked = useParams<{ tab?: string }>().tab;
  const [tab, setTab] = useState(asked === "system" ? asked : "games");
  const state = view.state;
  if (!state)
    return (
      <Screen>
        <Scroll>
          <Field label="Loading..." />
        </Scroll>
      </Screen>
    );
  return (
    <Screen tabs>
      <Tabs
        activeTab={tab}
        onShowTab={setTab}
        tabs={[
          { id: "games", title: "Games", content: <GamesTab view={view} state={state} /> },
          { id: "system", title: "System", content: <SystemTab view={view} state={state} /> },
        ]}
      />
    </Screen>
  );
}
