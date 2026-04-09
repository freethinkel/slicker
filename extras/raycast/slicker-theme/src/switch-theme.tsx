import { List, ActionPanel, Action, Icon, showToast, Toast, Color, showHUD } from "@raycast/api";
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

function getFirstWallpaper(themeDir: string): string | undefined {
  const bgDir = path.join(themeDir, "backgrounds");
  if (!fs.existsSync(bgDir)) return undefined;
  const files = fs.readdirSync(bgDir).filter((f) => /\.(png|jpe?g|webp)$/i.test(f)).sort();
  return files.length > 0 ? path.join(bgDir, files[0]) : undefined;
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

  return [`# ${theme.displayName}`, "", wallpaperPreview, "", `Accent \`${theme.colors?.accent || "—"}\``, `Text \`${theme.colors?.foreground || "—"}\``].join("\n");
}

function getLsPreviewColors(theme: ThemeEntry) {
  const c = theme.colors;
  if (!c) return null;
  return {
    directory: c.color4 || c.accent,
    symlink: c.color6 || c.accent,
    executable: c.color2 || c.accent,
    archive: c.color1 || c.accent,
    device: c.color3 || c.accent,
    normal: c.foreground,
  };
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
      await activeToastRef.current.hide().catch(() => {});
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
      {themes.map((theme) => {
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

        const lsColors = getLsPreviewColors(theme);

        return (
          <List.Item
            key={theme.name}
            id={theme.name}
            title={theme.displayName}
            subtitle={theme.isUser ? "user" : undefined}
            icon={{ source: Icon.Circle, tintColor: theme.colors?.accent as Color }}
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
                    {lsColors && (
                      <List.Item.Detail.Metadata.TagList title="ls -la">
                        <List.Item.Detail.Metadata.TagList.Item text="dir/" color={lsColors.directory} />
                        <List.Item.Detail.Metadata.TagList.Item text="link@" color={lsColors.symlink} />
                        <List.Item.Detail.Metadata.TagList.Item text="exec*" color={lsColors.executable} />
                        <List.Item.Detail.Metadata.TagList.Item text="archive" color={lsColors.archive} />
                        <List.Item.Detail.Metadata.TagList.Item text="device" color={lsColors.device} />
                        <List.Item.Detail.Metadata.TagList.Item text="file" color={lsColors.normal} />
                      </List.Item.Detail.Metadata.TagList>
                    )}
                  </List.Item.Detail.Metadata>
                }
              />
            }
            actions={
              <ActionPanel>
                <Action
                  title="Apply Theme"
                  icon={Icon.Brush}
                  shortcut={{ modifiers: [], key: "return" }}
                  onAction={() => switchTheme(theme)}
                />
              </ActionPanel>
            }
          />
        );
      })}
    </List>
  );
}
