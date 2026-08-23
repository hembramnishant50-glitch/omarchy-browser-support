<div align="center">

# 🌐 Omarchy Browser Support Pack

**Extended browser integration for Omarchy Linux** — install any browser, make it the system default, and launch site-specific web apps — all from the Shell menu.

![Browsers](https://img.shields.io/badge/browsers-12-2ea043)
![Scripts patched](https://img.shields.io/badge/scripts%20patched-4-f59e0b)
![Platform](https://img.shields.io/badge/platform-Arch%20Linux-1793d1)
![Window manager](https://img.shields.io/badge/wm-Hyprland-14b8a6)
![Display server](https://img.shields.io/badge/display-Wayland-c026d3)
![Shell](https://img.shields.io/badge/shell-Bash-4eaa25)

**12 browsers · 4 patched scripts · Quickshell menu integration**

</div>

---

## 🚀 Quick Start

> [!TIP]
> The installer patches browser scripts and adds Shell menu entries automatically.

```bash
bash <(curl -sL https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/install.sh)
omarchy restart shell
omarchy menu refresh
```

---

## 📑 Table of Contents

- [Supported Browsers](#supported-browsers)
- [What This Pack Changes](#what-this-pack-changes)
- [Installation](#installation)
- [Usage](#usage)
- [Shell Menu](#shell-menu)
- [Uninstall & Restore](#uninstall--restore)
- [Files](#files)
- [Browser Details](#browser-details)
- [Notes](#notes)
- [Links](#links)

---

## ✨ What You Get

<div align="center">

| 🌐 **12 Browsers** | 🧩 **4 Scripts + Menu** | ⚡ **One-Click Setup** |
| :---: | :---: | :---: |
| Chromium- and Firefox-based, from official repos **and** AUR | Default browser, install, remove, web apps + Quickshell menu | Auto-backups + package-based restore |

</div>

Every browser gets full integration:

- ✅ `omarchy default browser <name>` — set as system default
- 📦 `omarchy install browser <name>` — install from official repos or AUR
- 🗑️ `omarchy remove browser <name>` — clean removal with Chromium fallback
- 🪟 `omarchy launch webapp <url>` — site-specific window support
- 🗺️ Shell menu entries under **Setup → Defaults → Browser**, **Install → Browser**, and **Remove → Browser**

> [!NOTE]
> Omarchy ships with Chromium as the default browser. This pack does **not** change that — switch any time with `omarchy default browser <name>`.

---

## 🌐 Supported Browsers

### 🔷 Chromium-Based (7)

| Browser | Package | Source | Web Apps | Status |
|---------|---------|--------|----------|--------|
| Chromium | Pre-installed | — | `--app` | ✅ Default |
| Chrome | `google-chrome` | AUR | `--app` | ✅ |
| Brave | `brave-bin` | AUR | `--app` | ✅ |
| Brave Origin | `brave-origin-beta-bin` | AUR | `--app` | ✅ |
| Edge | `microsoft-edge-stable-bin` | AUR | `--app` | ✅ |
| **Vivaldi** | `vivaldi` | **Official** | `--app` | 🆕 |
| **Helium** | `helium-browser-bin` | AUR | `--app` | 🆕 |

### 🦊 Firefox-Based (5)

| Browser | Package | Source | Web Apps | Status |
|---------|---------|--------|----------|--------|
| Firefox | `firefox` | Official | `--new-window` | ✅ |
| Zen | `zen-browser-bin` | AUR | `--new-window` | ✅ |
| **Floorp** | `floorp-bin` | AUR | `--new-window` | 🆕 |
| **Waterfox** | `waterfox-bin` | AUR | `--new-window` | 🆕 |
| **LibreWolf** | `librewolf-bin` | AUR | `--new-window` | 🆕 |

**Legend:** ✅ = works out of the box · 🆕 = added by this pack · **Bold** = added by this pack

---

## 🧩 What This Pack Changes

Four Omarchy scripts are patched to recognize and handle every browser, plus a Quickshell menu extension adds browser entries:

| File | What it does |
|------|--------------|
| `omarchy-default-browser` | Detects and sets the default browser via `xdg-settings` and `xdg-mime` |
| `omarchy-install-browser` | Installs a browser from official repos or AUR with managed policies |
| `omarchy-remove-browser` | Removes a browser, cleans up config, falls back to Chromium |
| `omarchy-launch-webapp` | Launches a URL as a site-specific window using the correct flag per engine |
| `omarchy-browser-menu.jsonc` | Quickshell menu extension for Setup/Install/Remove browser entries |

### 🪟 Web App Behavior

| Engine | Flag | Behavior |
|--------|------|----------|
| 🔷 Chromium-based (Chrome, Brave, Edge, Vivaldi, Helium, …) | `--app` | No UI chrome, standalone window |
| 🦊 Firefox-based (Firefox, Zen, Floorp, Waterfox, LibreWolf) | `--new-window` | Opens in a normal browser window |
| ❓ Unknown / fallback | Chromium with `--app` | Falls back to Chromium |

> [!IMPORTANT]
> Before this pack, Firefox and Zen web apps **silently fell back to Chromium**.
> Now they use the user's preferred browser.

---

## ⚙️ Installation

### Prerequisites

- [Omarchy](https://omarchy.org/) (Arch Linux with Hyprland)
- Omarchy Shell (Quickshell-based, comes with Omarchy Quattro)
- `curl` (for one-click install)

### Option 1 — One-Click Install <sub>(recommended)</sub>

```bash
bash <(curl -sL https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/install.sh)
omarchy restart shell
omarchy menu refresh
```

This patches all 4 scripts and installs the Quickshell menu extension.

### Option 2 — Use Individual Browsers Without Patching

Even without this pack, you can install and use any of these browsers via
Omarchy's existing commands. Patching only adds Shell menu entries and
improves `omarchy launch webapp` behavior.

```bash
# Install any browser
omarchy install browser vivaldi
omarchy install browser helium
omarchy install browser floorp

# Set as default
omarchy default browser vivaldi
```

---

## ⌨️ Usage

### Command Cheat Sheet

| Command | Action |
|---------|--------|
| `omarchy default browser` | Show the current default |
| `omarchy default browser <name>` | Set a new default browser |
| `omarchy launch browser` | Open the default browser |
| `omarchy launch browser <url>` | Open a URL in the default browser |
| `omarchy launch webapp <url>` | Open a site-specific window |
| `omarchy install browser <name>` | Install a browser |
| `omarchy remove browser <name>` | Remove a browser + clean up |

### Examples

```bash
omarchy default browser vivaldi      # Set Vivaldi
omarchy default browser librewolf    # Set LibreWolf
omarchy default browser chromium     # Back to stock Chromium

omarchy launch browser https://x.com  # Open URL in default browser
omarchy launch webapp https://x.com   # Site-specific window

omarchy install browser floorp        # Install Floorp
omarchy remove browser waterfox       # Remove Waterfox + cleanup
```

---

## 🗺️ Shell Menu

Press `SUPER+Space` and navigate:

```
SUPER+Space
│
├─ Setup
│  └─ Defaults
│     └─ Browser ──────────────── choose from all 12
│
├─ Install
│  └─ Browser ─────────────────── pick any browser to install
│
└─ Remove
   └─ Browser ─────────────────── pick any browser to remove
```

---

## ♻️ Uninstall & Restore

### Option 1 — One-Click Restore

```bash
bash <(curl -sL https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/restore.sh)
omarchy restart shell
omarchy menu refresh
```

### Option 2 — Reinstall Omarchy Package

```bash
sudo pacman -S omarchy
omarchy restart shell
```

### Option 3 — Remove a Single Browser

```bash
# Remove the browser package and clean up
omarchy remove browser vivaldi
omarchy remove browser librewolf

# Reset default to Chromium if needed
omarchy default browser chromium
```

---

## 📁 Files

### Patched Scripts

Installed to `/usr/bin/` (package-based) or `~/.local/share/omarchy/bin/` (git-based):

| File | Purpose |
|------|---------|
| `omarchy-default-browser` | Detects and sets default browser (12 browsers) |
| `omarchy-install-browser` | Installs browsers with managed policies (11 install paths) |
| `omarchy-remove-browser` | Removes browsers with cleanup (11 remove paths) |
| `omarchy-launch-webapp` | Launches web apps with correct flags per engine |

### Quickshell Menu Extension

Installed to `~/.config/omarchy/`:

| File | Purpose |
|------|---------|
| `extensions/omarchy-browser-menu.jsonc` | Menu entries for Setup/Install/Remove |
| `providers/omarchy-browser-menu-provider` | Dynamic browser list provider |
| `providers/omarchy-browser-install-provider` | Install browser menu provider |
| `providers/omarchy-browser-remove-provider` | Remove browser menu provider |

---

## 🔍 Browser Details

### 🔷 Chromium-Based Browsers

| Browser | Desktop File | Executable | Private Flag | Policy Dir | Flags Config |
|---------|-------------|------------|-------------|------------|-------------|
| Chromium | `chromium.desktop` | `chromium` | `--incognito` | — | — |
| Chrome | `google-chrome.desktop` | `google-chrome-stable` | `--incognito` | `/etc/opt/chrome/policies/managed` | `~/.config/chrome-flags.conf` |
| Brave | `brave-browser.desktop` | `brave-browser` | `--incognito` | `/etc/brave/policies/managed` | `~/.config/brave-flags.conf` |
| Brave Origin | `brave-origin-beta.desktop` | `brave-origin-beta` | `--incognito` | `/etc/brave/policies/managed` | `~/.config/brave-origin-beta-flags.conf` |
| Edge | `microsoft-edge.desktop` | `microsoft-edge-stable` | `--inprivate` | `/etc/opt/edge/policies/managed` | `~/.config/microsoft-edge-stable-flags.conf` |
| **Vivaldi** | `vivaldi-stable.desktop` | `vivaldi-stable` | `--incognito` | `/etc/vivaldi/policies/managed` | `~/.config/vivaldi-flags.conf` |
| **Helium** | `helium.desktop` | `helium-browser` | `--incognito` | `/etc/helium/policies/managed` | `~/.config/helium-flags.conf` |

### 🦊 Firefox-Based Browsers

| Browser | Desktop File | Executable | Private Flag | Distribution Dir |
|---------|-------------|------------|-------------|-----------------|
| Firefox | `firefox.desktop` | `firefox` | `--private-window` | `/usr/lib/firefox/distribution` |
| Zen | `zen.desktop` | `zen-browser` | `--private-window` | `/opt/zen-browser/distribution` |
| **Floorp** | `floorp.desktop` | `floorp` | `--private-window` | `/usr/lib/floorp/distribution` |
| **Waterfox** | `waterfox.desktop` | `waterfox` | `--private-window` | `/usr/lib/waterfox/distribution` |
| **LibreWolf** | `librewolf.desktop` | `librewolf` | `--private-window` | `/usr/lib/librewolf/distribution` |

---

## 📝 Notes

- **📦 Persistence:** Patched files live in `/usr/bin/` (package-based) or
  `~/.local/share/omarchy/bin/` (git-based). Running `omarchy update` may
  overwrite them. Simply re-run `install.sh` after updates.

- **♻️ Restore:** Use `restore.sh` or `sudo pacman -S omarchy` to restore
  originals. The restore script handles both git-based and package-based
  installations.

- **🔑 Default browser:** Omarchy ships with Chromium as the system default.
  This pack does not change that. Switch at any time with
  `omarchy default browser <name>`.

- **🎨 Icon glyphs:** Each browser uses a Nerd Font icon. Browsers sharing the
  same engine share the same icon family (e.g. all Firefox forks use `󰈹`).

- **🪟 Wayland:** Firefox-based browsers get `MOZ_ENABLE_WAYLAND=1` set via
  `~/.config/environment.d/omarchy-firefox-wayland.conf` at install time.

- **🔄 Shell Integration:** This pack is designed for Omarchy Quattro with the
  Quickshell-based Omarchy Shell. Browser menus use JSONC extensions and
  provider scripts instead of the old bash menu system.

---

## 🔗 Links

| Project | Link |
|---------|------|
| Omarchy | [omarchy.org](https://omarchy.org/) |
| Helium Browser | [helium.computer](https://helium.computer/) |
| Vivaldi Browser | [vivaldi.com](https://vivaldi.com/) |
| Floorp Browser | [floorp.app](https://floorp.app/) |
| Waterfox Browser | [waterfox.net](https://www.waterfox.net/) |
| LibreWolf Browser | [librewolf.net](https://librewolf.net/) |
| AUR · helium-browser-bin | [aur.archlinux.org](https://aur.archlinux.org/packages/helium-browser-bin) |
| AUR · floorp-bin | [aur.archlinux.org](https://aur.archlinux.org/packages/floorp-bin) |
| AUR · waterfox-bin | [aur.archlinux.org](https://aur.archlinux.org/packages/waterfox-bin) |
| AUR · librewolf-bin | [aur.archlinux.org](https://aur.archlinux.org/packages/librewolf-bin) |

---

<div align="center">

Made for **Omarchy Quattro** · Arch Linux · Hyprland · Wayland · Quickshell

</div>
