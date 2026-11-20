import { ButtonItem, ConfirmModal, Field, PanelSection, PanelSectionRow, showModal, staticClasses } from "@decky/ui";
import { definePlugin, routerHook } from "@decky/api";
import { FaGamepad } from "react-icons/fa";
import {
  autoSync,
  installEmulator,
  latestRelease,
  reboot,
  short,
  toast,
  updatePlugin,
  usePlugin,
} from "./api";
import { GamePage } from "./game";
import { patchLibraryMenu } from "./menu";
import { Page } from "./page";
import { GAME_PAGE, PAGE_ROUTE, openPage } from "./routes";

const confirm = (title: string, text: string, ok: string, action: () => void) =>
  showModal(<ConfirmModal strTitle={title} strDescription={text} strOKButtonText={ok} onOK={action} />);

// The side panel: Lichii BC-250 itself (version, install, updates) and the way to the plugin's page,
// where the games and the BC-250 tuning are.
function Content() {
  const { state, release, setRelease, busy, syncing, run } = usePlugin();

  if (!state) return <PanelSection><PanelSectionRow><Field label="Loading..." /></PanelSectionRow></PanelSection>;

  const emulatorUpdate = !!release?.emulator_url && release.tag !== state.emulator_version;
  const pluginUpdate = !!release?.plugin_url && release.tag !== (state.plugin_release || state.plugin_version);
  const tuningOff = state.tuning.filter((it) => !it.on && it.method !== "unsupported").length;

  return (
    <>
      <PanelSection>
        <PanelSectionRow>
          <Field
            label="Version"
            description={
              !state.bc250 ? "Not a BC-250: shortcuts still work, the tuning does not apply"
                : state.game_running ? "A game is running" : "Installed for the BC-250"
            }
          >
            {state.emulator_installed ? short(state.emulator_version) || "installed" : "not installed"}
          </Field>
        </PanelSectionRow>
        {!state.emulator_installed && (
          <PanelSectionRow>
            <ButtonItem
              layout="below"
              disabled={!!busy || state.game_running || !release?.emulator_url}
              onClick={() =>
                run("Installing Lichii BC-250", async () => {
                  const r = await installEmulator(release!.emulator_url!, release!.tag, release!.sum_url ?? "");
                  toast(r.ok ? `Installed ${short(release!.tag)}` : r.log || "failed");
                })
              }
            >
              {busy === "Installing Lichii BC-250" ? "Installing..." : release?.emulator_url ? "Install" : "No release found"}
            </ButtonItem>
          </PanelSectionRow>
        )}
        {state.emulator_installed && (
          <PanelSectionRow>
            <ButtonItem
              layout="below"
              description={
                emulatorUpdate || pluginUpdate
                  ? `${short(release!.tag)} is out: press to update`
                  : `Plugin ${short(state.plugin_release) || state.plugin_version}: press to check`
              }
              disabled={!!busy || ((emulatorUpdate || pluginUpdate) && state.game_running)}
              onClick={() =>
                emulatorUpdate || pluginUpdate
                  ? run("Update", async () => {
                      if (emulatorUpdate) {
                        const r = await installEmulator(release!.emulator_url!, release!.tag, release!.sum_url ?? "");
                        if (!r.ok) {
                          toast(r.log || "failed");
                          return;
                        }
                        toast(`Lichii BC-250 ${short(release!.tag)} installed`);
                      }
                      if (pluginUpdate) await updatePlugin(release!);
                    })
                  : run("Check", async () => {
                      const r = await latestRelease();
                      setRelease(r);
                      const emulator = !!r.emulator_url && r.tag !== state.emulator_version;
                      const plugin = !!r.plugin_url && !!state.plugin_release && r.tag !== state.plugin_release;
                      toast(r.error ? `No connection to GitHub: ${r.error}` : emulator || plugin ? `${short(r.tag)} is out` : "Up to date");
                    })
              }
            >
              {busy === "Update" ? "Updating..." : busy === "Check" ? "Checking..." : "Updates"}
            </ButtonItem>
          </PanelSectionRow>
        )}
        {release?.error && (
          <PanelSectionRow>
            <Field label="No connection to GitHub" description={release.error} />
          </PanelSectionRow>
        )}
      </PanelSection>

      <PanelSection title="Games">
        <PanelSectionRow>
          <ButtonItem
            layout="below"
            description={
              !state.emulator_installed
                ? "Install Lichii BC-250 first"
                : syncing
                  ? "Adding to Steam..."
                  : `${state.games.length} ${state.games.length === 1 ? "game" : "games"} in the library: each one's page, the games folder`
            }
            onClick={() => openPage()}
          >
            Games
          </ButtonItem>
        </PanelSectionRow>
        <PanelSectionRow>
          <ButtonItem
            layout="below"
            description={tuningOff ? `${tuningOff} board settings are off: memory, swap, GTT` : "Board settings are on"}
            onClick={() => openPage("system")}
          >
            BC-250 tuning
          </ButtonItem>
        </PanelSectionRow>
        {state.tuning.some((it) => it.configured && !it.on) && (
          <PanelSectionRow>
            <ButtonItem
              layout="below"
              description="The kernel and zram settings are read at boot"
              disabled={!!busy || state.game_running}
              onClick={() => confirm("Reboot", "Reboot now for the settings to take effect?", "Reboot", () => reboot())}
            >
              Reboot needed
            </ButtonItem>
          </PanelSectionRow>
        )}
      </PanelSection>
    </>
  );
}

export default definePlugin(() => {
  const auto = () => autoSync().catch((e) => console.error("Lichii BC-250 sync", e));
  setTimeout(auto, 15000);
  const timer = setInterval(auto, 10 * 60 * 1000);
  routerHook.addRoute(PAGE_ROUTE, Page, { exact: true });
  routerHook.addRoute(GAME_PAGE, GamePage, { exact: true });
  const unpatchMenu = patchLibraryMenu();
  return {
    name: "Lichii-BC250",
    titleView: <div className={staticClasses.Title}>Lichii BC-250</div>,
    content: <Content />,
    icon: <FaGamepad />,
    onDismount() {
      clearInterval(timer);
      unpatchMenu();
      routerHook.removeRoute(PAGE_ROUTE);
      routerHook.removeRoute(GAME_PAGE);
    },
  };
});
