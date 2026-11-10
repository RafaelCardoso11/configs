import { Action, ActionPanel, Grid, Icon, closeMainWindow, open } from "@vicinae/api";
import { execFile, spawn } from "node:child_process";
import { createHash } from "node:crypto";
import { mkdir, readdir, stat } from "node:fs/promises";
import { homedir } from "node:os";
import { basename, dirname, extname, join, relative } from "node:path";
import { promisify } from "node:util";
import { useEffect, useMemo, useState } from "react";

const run = promisify(execFile);

const WALL_DIR = join(homedir(), "Pictures/wallpapers");
const THUMB_DIR = join(homedir(), ".cache/vicinae-wallpapers");
const APPLY_SCRIPT = join(homedir(), ".config/hypr/UserScripts/WallpaperSelect.sh");
const IMAGE_EXT = new Set([".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".webp"]);
const VIDEO_EXT = new Set([".mp4", ".mkv", ".mov", ".webm"]);
const THUMB_JOBS = 6;

type Wallpaper = { path: string; title: string; section: string; thumb?: string };

const pretty = (s: string) => s.replace(/[-_]+/g, " ").replace(/\s+/g, " ").trim();

async function scan(): Promise<Wallpaper[]> {
  const entries = await readdir(WALL_DIR, { recursive: true });
  const walls: Wallpaper[] = [];
  for (const rel of entries) {
    const ext = extname(rel).toLowerCase();
    if (!IMAGE_EXT.has(ext) && !VIDEO_EXT.has(ext)) continue;
    const path = join(WALL_DIR, rel);
    const dir = dirname(rel);
    walls.push({
      path,
      title: pretty(basename(rel, extname(rel))),
      section: dir === "." ? "Wallpapers" : dir.split("/").map(pretty).join(" · "),
    });
  }
  return walls.sort((a, b) => a.section.localeCompare(b.section) || a.title.localeCompare(b.title));
}

async function thumbFor(path: string): Promise<string | undefined> {
  if (VIDEO_EXT.has(extname(path).toLowerCase())) return undefined;
  const { mtimeMs } = await stat(path);
  const out = join(THUMB_DIR, createHash("sha1").update(`${path}:${mtimeMs}`).digest("hex") + ".jpg");
  try {
    await stat(out);
  } catch {
    await run("vipsthumbnail", [path, "-s", "480x270", "-o", `${out}[Q=82]`]);
  }
  return out;
}

async function currentWallpaper(): Promise<string | undefined> {
  try {
    const { stdout: mons } = await run("hyprctl", ["monitors", "-j"]);
    const focused = JSON.parse(mons).find((m: { focused: boolean }) => m.focused)?.name;
    const { stdout } = await run("swww", ["query"]);
    const line = stdout.split("\n").find((l) => l.startsWith(`: ${focused}:`));
    return line?.split("image: ")[1]?.trim();
  } catch {
    return undefined;
  }
}

function apply(path: string) {
  spawn(APPLY_SCRIPT, [path], { detached: true, stdio: "ignore" }).unref();
  closeMainWindow();
}

export default function Command() {
  const [walls, setWalls] = useState<Wallpaper[]>([]);
  const [current, setCurrent] = useState<string>();
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    (async () => {
      currentWallpaper().then(setCurrent);
      await mkdir(THUMB_DIR, { recursive: true });
      const list = await scan();
      setWalls(list);

      // thumbnails are generated once and cached; flush to the UI in batches so the grid fills in as they land
      const thumbs = new Map<string, string>();
      let next = 0;
      let pending = 0;
      const flush = () => setWalls((ws) => ws.map((w) => (thumbs.has(w.path) ? { ...w, thumb: thumbs.get(w.path) } : w)));
      const worker = async () => {
        while (next < list.length) {
          const w = list[next++];
          const t = await thumbFor(w.path).catch(() => undefined);
          if (t) thumbs.set(w.path, t);
          if (++pending % 60 === 0) flush();
        }
      };
      await Promise.all(Array.from({ length: THUMB_JOBS }, worker));
      flush();
      setLoading(false);
    })();
  }, []);

  const sections = useMemo(() => {
    const map = new Map<string, Wallpaper[]>();
    for (const w of walls) map.set(w.section, [...(map.get(w.section) ?? []), w]);
    return [...map];
  }, [walls]);

  const randomPath = () => walls[Math.floor(Math.random() * walls.length)]?.path;

  const item = (w: Wallpaper, keyPrefix = "") => (
    <Grid.Item
      key={keyPrefix + w.path}
      id={keyPrefix + w.path}
      title={w.title}
      keywords={[w.section]}
      content={w.thumb ? w.thumb : { fileIcon: w.path }}
      accessory={w.path === current ? { icon: Icon.CheckCircle, tooltip: "Current wallpaper" } : undefined}
      actions={
        <ActionPanel>
          <Action title="Set Wallpaper" icon={Icon.Image} onAction={() => apply(w.path)} />
          <Action
            title="Random Wallpaper"
            icon={Icon.Shuffle}
            shortcut={{ modifiers: ["ctrl"], key: "r" }}
            onAction={() => {
              const p = randomPath();
              if (p) apply(p);
            }}
          />
          <Action title="Show in Files" icon={Icon.Folder} shortcut={{ modifiers: ["ctrl"], key: "o" }} onAction={() => open(dirname(w.path))} />
        </ActionPanel>
      }
    />
  );

  const currentWall = walls.find((w) => w.path === current);

  return (
    <Grid columns={4} aspectRatio="16/9" fit={Grid.Fit.Fill} isLoading={loading} searchBarPlaceholder="Search wallpapers...">
      {currentWall && <Grid.Section title="Current">{item(currentWall, "current:")}</Grid.Section>}
      {sections.map(([title, ws]) => (
        <Grid.Section key={title} title={title} subtitle={String(ws.length)}>
          {ws.map((w) => item(w))}
        </Grid.Section>
      ))}
    </Grid>
  );
}
