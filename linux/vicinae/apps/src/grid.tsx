import {
  Action,
  ActionPanel,
  Alert,
  Application,
  Grid,
  Icon,
  Keyboard,
  Toast,
  closeMainWindow,
  confirmAlert,
  getApplications,
  runInTerminal,
  showToast,
} from "@vicinae/api";
import { execFile, spawn } from "node:child_process";
import { realpath, unlink } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";
import { useEffect, useState } from "react";

const run = promisify(execFile);
const LOCAL_APPS = join(homedir(), ".local/share/applications");

function launch(app: Application) {
  // path is the app's .desktop file; gio runs it with its Exec line, detached from vicinae
  spawn("gio", ["launch", app.path], { detached: true, stdio: "ignore" }).unref();
  closeMainWindow();
}

async function owningPackage(desktopFile: string): Promise<string | undefined> {
  try {
    const { stdout } = await run("pacman", ["-Qqo", await realpath(desktopFile)]);
    return stdout.trim() || undefined;
  } catch {
    return undefined;
  }
}

// Packaged apps (pacman/AUR) are removed in a terminal so sudo and pacman's own prompt stay with the user;
// user-level shortcuts (e.g. browser web apps) only lose their .desktop file.
async function uninstall(app: Application, reload: () => void) {
  const pkg = await owningPackage(app.path);
  if (pkg) {
    await runInTerminal(["sudo", "pacman", "-Rns", pkg], { hold: true, title: `Uninstall ${app.name}` });
    closeMainWindow();
    return;
  }
  if (app.path.startsWith(LOCAL_APPS + "/")) {
    const ok = await confirmAlert({
      title: `Remove ${app.name}?`,
      message: `Deletes the shortcut ${app.path}`,
      primaryAction: { title: "Remove", style: Alert.ActionStyle.Destructive },
    });
    if (!ok) return;
    await unlink(app.path);
    await showToast({ style: Toast.Style.Success, title: `${app.name} removed` });
    reload();
    return;
  }
  await showToast({ style: Toast.Style.Failure, title: "Can't uninstall", message: "Not owned by any pacman package" });
}

export default function Command() {
  const [apps, setApps] = useState<Application[]>();

  const load = () => getApplications().then((list) => setApps([...list].sort((a, b) => a.name.localeCompare(b.name))));
  useEffect(() => {
    load();
  }, []);

  return (
    <Grid columns={7} aspectRatio="1" fit={Grid.Fit.Contain} inset={Grid.Inset.Medium} isLoading={!apps} searchBarPlaceholder="Search apps...">
      {apps?.map((app) => (
        <Grid.Item
          key={app.id}
          title={app.name}
          content={app.icon ? { source: app.icon, fallback: Icon.AppWindow } : Icon.AppWindow}
          actions={
            <ActionPanel>
              <Action title="Open" icon={Icon.ArrowRight} onAction={() => launch(app)} />
              <Action
                title="Uninstall"
                icon={Icon.Trash}
                style="destructive"
                shortcut={Keyboard.Shortcut.Common.Remove}
                onAction={() => uninstall(app, load)}
              />
            </ActionPanel>
          }
        />
      ))}
    </Grid>
  );
}
