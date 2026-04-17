import { List, Grid, ActionPanel, Action, Icon, showToast, Toast, Color, showHUD, useNavigation } from "@raycast/api";
import { exec, type ChildProcess } from "child_process";
import fs from "fs";
import path from "path";
import { useState, useMemo, useEffect, useRef } from "react";

const SLICKER_DIR = path.join(process.env.HOME || "", ".config", "slicker");
const THEMES_DIR = path.join(SLICKER_DIR, "themes");
const USER_THEMES_DIR = path.join(SLICKER_DIR, "user", "themes");
const CURRENT_FILE = path.join(SLICKER_DIR, "theme", ".current");
const SLICKER_BIN = path.join(SLICKER_DIR, "bin", "slicker");

interface ThemeColors {
  accent: string;
  cursor: string;
  foreground: string;
  background: string;
  selection_foreground: string;
  selection_background: string;
  [key: string]: string;
}

interface ThemeEntry {
  name: string;
  displayName: string;
  colors: ThemeColors | null;
  isUser: boolean;
  isDark: boolean;
  bgCount: number;
  wallpaperPath?: string;
}

function parseColorsToml(filepath: string): ThemeColors | null {
  try {
    const content = fs.readFileSync(filepath, "utf-8");
    const colors: Record<string, string> = {};
    for (const line of content.split("\n")) {
      const match = line.match(/^(\w+)\s*=\s*"([^"]+)"/);
      if (match) {
        colors[match[1]] = match[2];
      }
    }
    if (!colors.accent || !colors.foreground || !colors.background) return null;
    return colors as unknown as ThemeColors;
  } catch {
    return null;
  }
}

function getCurrentTheme(): string {
  try {
    return fs.readFileSync(CURRENT_FILE, "utf-8").trim();
  } catch {
    return "";
  }
}

function getWallpapers(themeDir: string): string[] {
  const bgDir = path.join(themeDir, "backgrounds");
  if (!fs.existsSync(bgDir)) return [];
  return fs
    .readdirSync(bgDir)
    .filter((f) => /\.(png|jpe?g|webp)$/i.test(f))
    .sort()
    .map((f) => path.join(bgDir, f));
}

function getFirstWallpaper(themeDir: string): string | undefined {
  const wallpapers = getWallpapers(themeDir);
  return wallpapers[0];
}

function resolveThemeDir(themeName: string): string | undefined {
  const userDir = path.join(USER_THEMES_DIR, themeName);
  if (fs.existsSync(userDir)) return userDir;
  const baseDir = path.join(THEMES_DIR, themeName);
  if (fs.existsSync(baseDir)) return baseDir;
  return undefined;
}

function WallpaperGrid({ theme }: { theme: ThemeEntry }) {
  const { pop } = useNavigation();
  const themeDir = useMemo(() => resolveThemeDir(theme.name), [theme.name]);
  const wallpapers = useMemo(() => (themeDir ? getWallpapers(themeDir) : []), [themeDir]);

  async function applyWallpaper(imgPath: string) {
    const toast = await showToast({
      style: Toast.Style.Animated,
      title: `Setting wallpaper...`,
    });
    try {
      await new Promise<void>((resolve, reject) => {
        exec(
          `/bin/bash -l -c '"${SLICKER_BIN}" wallpaper set "${imgPath}"'`,
          { timeout: 15000 },
          (err) => (err ? reject(err) : resolve()),
        );
      });
      await toast.hide();
      await showHUD(`Wallpaper: ${path.basename(imgPath)}`);
      pop();
    } catch (e) {
      toast.style = Toast.Style.Failure;
      toast.title = "Failed";
      toast.message = String(e);
    }
  }

  return (
    <Grid
      columns={4}
      aspectRatio="16/9"
      fit={Grid.Fit.Fill}
      navigationTitle={`${theme.displayName} · Wallpapers`}
      searchBarPlaceholder="Search wallpapers..."
    >
      {wallpapers.map((wp) => (
        <Grid.Item
          key={wp}
          content={{ source: wp }}
          title={path.basename(wp)}
          actions={
            <ActionPanel>
              <Action
                title="Set as Wallpaper"
                icon={Icon.Image}
                onAction={() => applyWallpaper(wp)}
              />
              <Action.ShowInFinder path={wp} />
              <Action.CopyToClipboard title="Copy Path" content={wp} />
            </ActionPanel>
          }
        />
      ))}
    </Grid>
  );
}

function getThemes(): ThemeEntry[] {
  const themes: ThemeEntry[] = [];
  const seen = new Set<string>();

  const addFromDir = (dir: string, isUser: boolean) => {
    if (!fs.existsSync(dir)) return;
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      if (!entry.isDirectory() || entry.name === "templates" || seen.has(entry.name)) continue;
      const themeDir = path.join(dir, entry.name);
      const colorsFile = path.join(themeDir, "colors.toml");
      const colors = parseColorsToml(colorsFile);
      const isDark = !fs.existsSync(path.join(themeDir, "light.mode"));
      const bgDir = path.join(themeDir, "backgrounds");
      const bgCount = fs.existsSync(bgDir)
        ? fs.readdirSync(bgDir).filter((f) => /\.(png|jpe?g|webp)$/i.test(f)).length
        : 0;
      const wallpaperPath = getFirstWallpaper(themeDir);

      themes.push({
        name: entry.name,
        displayName: entry.name
          .split("-")
          .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
          .join(" "),
        colors,
        isUser,
        isDark,
        bgCount,
        wallpaperPath,
      });
      seen.add(entry.name);
    }
  };

  addFromDir(USER_THEMES_DIR, true);
  addFromDir(THEMES_DIR, false);

  return themes.sort((a, b) => a.name.localeCompare(b.name));
}

function getThemePreview(theme: ThemeEntry): string {
  const wallpaperPreview = theme.wallpaperPath
    ? `![${theme.displayName}](${encodeURI(`file://${theme.wallpaperPath}`)})`
    : "_No wallpaper preview_";

  return `
${wallpaperPreview}

# ${theme.displayName} 
`;
}


export default function Command() {
  const [current, setCurrent] = useState(getCurrentTheme);
  const [pendingTheme, setPendingTheme] = useState<string | null>(null);
  const themes = useMemo(getThemes, []);
  const applyIdRef = useRef(0);
  const activeChildRef = useRef<ChildProcess | null>(null);
  const activeToastRef = useRef<Toast | null>(null);
  const pendingRef = useRef<string | null>(null);

  useEffect(() => {
    const sync = () => {
      if (pendingRef.current) return;
      const next = getCurrentTheme();
      setCurrent((prev) => (prev === next ? prev : next));
    };
    sync();
    const interval = setInterval(sync, 750);
    return () => clearInterval(interval);
  }, []);

  async function switchTheme(theme: ThemeEntry) {
    const applyId = ++applyIdRef.current;

    // Kill previous in-flight process
    if (activeChildRef.current) {
      activeChildRef.current.kill("SIGTERM");
      activeChildRef.current = null;
    }
    if (activeToastRef.current) {
      await activeToastRef.current.hide().catch(() => { });
      activeToastRef.current = null;
    }

    setPendingTheme(theme.name);
    pendingRef.current = theme.name;
    setCurrent(theme.name);

    const toast = await showToast({
      style: Toast.Style.Animated,
      title: `Switching to ${theme.displayName}...`,
    });
    activeToastRef.current = toast;

    try {
      await new Promise<void>((resolve, reject) => {
        const child = exec(
          `/bin/bash -l -c '"${SLICKER_BIN}" theme set "${theme.name}"'`,
          { timeout: 15000 },
          (err) => {
            if (activeChildRef.current === child) activeChildRef.current = null;
            if (applyId !== applyIdRef.current) {
              resolve();
              return;
            }
            if (err) {
              reject(err);
            } else {
              resolve();
            }
          },
        );
        activeChildRef.current = child;
      });
      if (applyId !== applyIdRef.current) return;
      setCurrent(theme.name);
      setPendingTheme(null);
      pendingRef.current = null;
      await toast.hide();
      if (activeToastRef.current === toast) activeToastRef.current = null;
      await showHUD(`Switched to ${theme.displayName}`);
    } catch (e) {
      if (applyId !== applyIdRef.current) return;
      setPendingTheme(null);
      pendingRef.current = null;
      setCurrent(getCurrentTheme());
      toast.style = Toast.Style.Failure;
      toast.title = "Failed";
      toast.message = String(e);
      if (activeToastRef.current === toast) activeToastRef.current = null;
    }
  }

  return (
    <List
      isShowingDetail
      searchBarPlaceholder="Search themes..."
    >
      {themes.slice().sort((a, b) => a.isUser && !b.isUser ? -1 : !a.isUser && b.isUser ? 1 : 0).map((theme) => {
        const isCurrent = theme.name === (pendingTheme || current);
        const accessories: List.Item.Accessory[] = [];
        if (isCurrent) accessories.push({ tag: { value: "active", color: Color.Green } });
        accessories.push({
          icon: {
            source: theme.isDark ? Icon.Moon : Icon.Sun,
            tintColor: (theme.isDark ? "#cccccc" : "#333333") as Color,
          },
        });
        if (theme.bgCount > 0) accessories.push({ text: `${theme.bgCount} bg` });


        return (
          <List.Item
            key={theme.name}
            id={theme.name}
            title={theme.displayName}
            subtitle={theme.isUser ? "user" : undefined}
            icon={{ source: Icon.CircleFilled, tintColor: theme.colors?.accent as Color }}
            accessories={accessories}
            detail={
              <List.Item.Detail
                markdown={getThemePreview(theme)}
                metadata={
                  <List.Item.Detail.Metadata>
                    <List.Item.Detail.Metadata.Label title="Mode" text={theme.isDark ? "Dark" : "Light"} />
                    <List.Item.Detail.Metadata.Separator />
                    <List.Item.Detail.Metadata.Label title="Wallpapers" text={String(theme.bgCount)} />
                    <List.Item.Detail.Metadata.Separator />
                    <List.Item.Detail.Metadata.TagList title="Colors">
                      <List.Item.Detail.Metadata.TagList.Item color={theme.colors?.color1} icon={Icon.CircleFilled} />
                      <List.Item.Detail.Metadata.TagList.Item color={theme.colors?.color2} icon={Icon.CircleFilled} />
                      <List.Item.Detail.Metadata.TagList.Item color={theme.colors?.color3} icon={Icon.CircleFilled} />
                      <List.Item.Detail.Metadata.TagList.Item color={theme.colors?.color4} icon={Icon.CircleFilled} />
                    </List.Item.Detail.Metadata.TagList>
                  </List.Item.Detail.Metadata>
                }
              />
            }
            actions={
              <ActionPanel>
                <Action
                  title="Apply Theme"
                  icon={Icon.Brush}
                  onAction={() => switchTheme(theme)}
                />
                {theme.bgCount > 0 && (
                  <Action.Push
                    title="Show Wallpapers"
                    icon={Icon.Image}
                    shortcut={{ modifiers: ["cmd"], key: "w" }}
                    target={<WallpaperGrid theme={theme} />}
                  />
                )}
              </ActionPanel>
            }
          />
        );
      })}
    </List>
  );
}
