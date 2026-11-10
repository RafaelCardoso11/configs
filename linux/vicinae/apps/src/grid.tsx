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
import { readFile, realpath, unlink } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";
import { useEffect, useState } from "react";

const run = promisify(execFile);
const LOCAL_APPS = join(homedir(), ".local/share/applications");

// freedesktop main categories, in the order a multi-category app is resolved
const SECTIONS: [string, string][] = [
  ["Development", "Development"],
  ["Game", "Games"],
  ["Graphics", "Graphics"],
  ["AudioVideo", "Media"],
  ["Audio", "Media"],
  ["Video", "Media"],
  ["Office", "Office"],
  ["Education", "Education"],
  ["Science", "Science"],
  ["Network", "Internet"],
  ["Settings", "Settings"],
  ["System", "System"],
  ["Utility", "Utilities"],
];
const OTHER = "Other";

type App = Application & { section: string; hidden: boolean };

async function describe(app: Application): Promise<App> {
  try {
    const text = await readFile(app.path, "utf8");
    // getApplications() also returns helper entries apps install for menus to skip (e.g. VS Code's URL handler)
    const hidden = /^(NoDisplay|Hidden)=true\s*$/m.test(text);
    return { ...app, hidden, section: sectionFromDesktop(text) };
  } catch {
    return { ...app, hidden: false, section: OTHER };
  }
}

function sectionFromDesktop(text: string): string {
  {
    // browser-installed web apps (Brave/Chrome "Install app") carry no Categories, only --app-id
    if (/^Exec=.*--app-id=/m.test(text)) return "Web Apps";
    const cats = (text.match(/^Categories=(.*)$/m)?.[1] ?? "").split(";");
    return SECTIONS.find(([cat]) => cats.includes(cat))?.[1] ?? OTHER;
  }
}

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

// alphabetical sections, "Other" last
function sections(apps: App[] = []): [string, App[]][] {
  const map = new Map<string, App[]>();
  for (const app of apps) map.set(app.section, [...(map.get(app.section) ?? []), app]);
  return [...map].sort(([a], [b]) => (a === OTHER ? 1 : b === OTHER ? -1 : a.localeCompare(b)));
}

export default function Command() {
  const [apps, setApps] = useState<App[]>();

  const load = async () => {
    const list = await getApplications();
    const described = await Promise.all(list.map(describe));
    setApps(described.filter((app) => !app.hidden).sort((a, b) => a.name.localeCompare(b.name)));
  };
  useEffect(() => {
    load();
  }, []);

  return (
    <Grid columns={7} aspectRatio="1" fit={Grid.Fit.Contain} inset={Grid.Inset.Medium} isLoading={!apps} searchBarPlaceholder="Search apps...">
      {sections(apps).map(([title, items]) => (
        <Grid.Section key={title} title={title} subtitle={String(items.length)}>
          {items.map((app) => (
            <Grid.Item
              key={app.id}
              title={app.name}
              keywords={[app.section]}
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
        </Grid.Section>
      ))}
    </Grid>
  );
}
