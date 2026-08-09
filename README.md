<div align="center">

# 🌐 Omarchy Browser Support Pack

**Extended browser integration for Omarchy Linux** — install any browser, make it the system default, and launch site-specific web apps — all from the Walker menu.

![Browsers](https://img.shields.io/badge/browsers-12-2ea043)
![Scripts patched](https://img.shields.io/badge/scripts%20patched-5-f59e0b)
![Platform](https://img.shields.io/badge/platform-Arch%20Linux-1793d1)
![Window manager](https://img.shields.io/badge/wm-Hyprland-14b8a6)
![Display server](https://img.shields.io/badge/display-Wayland-c026d3)
![Shell](https://img.shields.io/badge/shell-Bash-4eaa25)

**12 browsers · 5 patched scripts · one-click setup**

</div>

---

## 🚀 Quick Start

> [!TIP]
> The installer backs up your original scripts automatically and installs all 5 patched files in one go.

```bash
bash <(curl -sL https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/install.sh)
omarchy restart walker
```

---

## 📑 Table of Contents

- [Supported Browsers](#supported-browsers)
- [What This Pack Changes](#what-this-pack-changes)
- [Installation](#installation)
- [Usage](#usage)
- [Walker Menu](#walker-menu)
- [Uninstall & Restore](#uninstall--restore)
- [Files](#files)
- [Browser Details](#browser-details)
- [Notes](#notes)
- [Links](#links)

---

## ✨ What You Get

<div align="center">

| 🌐 **12 Browsers** | 🧩 **5 Scripts Patched** | ⚡ **One-Click Setup** |
| :---: | :---: | :---: |
| Chromium- and Firefox-based, from official repos **and** AUR | Default browser, install, remove, menus, web apps | Auto-backups + git-based restore, no manual work |

</div>

Every browser gets full integration:

- ✅ `omarchy default browser <name>` — set as system default
- 📦 `omarchy install browser <name>` — install from official repos or AUR
- 🗑️ `omarchy remove browser <name>` — clean removal with Chromium fallback
- 🪟 `omarchy launch webapp <url>` — site-specific window support
- 🗺️ Walker menu entries under **Setup → Defaults → Browser**, **Install → Browser**, and **Remove → Browser**

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

Five Omarchy scripts are patched to recognize and handle every browser:

| Script | What it does |
|--------|--------------|
| `omarchy-default-browser` | Detects and sets the default browser via `xdg-settings` and `xdg-mime` |
| `omarchy-install-browser` | Installs a browser from official repos or AUR with managed policies |
| `omarchy-remove-browser` | Removes a browser, cleans up config, falls back to Chromium |
| `omarchy-menu` | Adds browser entries to the Walker menus (Setup / Install / Remove) |
| `omarchy-launch-webapp` | Launches a URL as a site-specific window using the correct flag per engine |

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
- Walker (default launcher, comes with Omarchy)
- `curl` (for one-click install)

### Option 1 — One-Click Install <sub>(recommended)</sub>

```bash
bash <(curl -sL https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/install.sh)
omarchy restart walker
```

This downloads all 5 patched scripts, backs up the originals, and installs them.

### Option 2 — Manual Install

```bash
# Download patched scripts
curl -LO https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/omarchy-default-browser
curl -LO https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/omarchy-install-browser
curl -LO https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/omarchy-remove-browser
curl -LO https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/omarchy-menu
curl -LO https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/omarchy-launch-webapp
chmod +x omarchy-*

# Back up originals (optional but recommended)
cp ~/.local/share/omarchy/bin/omarchy-default-browser{,.bak}
cp ~/.local/share/omarchy/bin/omarchy-install-browser{,.bak}
cp ~/.local/share/omarchy/bin/omarchy-remove-browser{,.bak}
cp ~/.local/share/omarchy/bin/omarchy-menu{,.bak}
cp ~/.local/share/omarchy/bin/omarchy-launch-webapp{,.bak}

# Install patched versions
cp omarchy-* ~/.local/share/omarchy/bin/

# Restart Walker
omarchy restart walker
```

### Option 3 — Use Individual Browsers Without Patching

Even without this pack, you can install and use any of these browsers via
Omarchy's existing commands. Patching only adds Walker menu entries and
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

## 🗺️ Walker Menu

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
omarchy restart walker
```

The restore script uses `git checkout` from the Omarchy repository at
`~/.local/share/omarchy/` to restore the original files. No backup files
are required — the git repo always has the pristine originals.

### Option 2 — Manual Restore

```bash
cd ~/.local/share/omarchy
git checkout -- bin/omarchy-default-browser \
               bin/omarchy-install-browser \
               bin/omarchy-remove-browser \
               bin/omarchy-menu \
               bin/omarchy-launch-webapp
omarchy restart walker
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

All files live in `~/.local/share/omarchy/bin/`:

| File | Size | Lines Changed |
|------|------|---------------|
| `omarchy-default-browser` | 2.3 KB | +10 browser entries |
| `omarchy-install-browser` | 3.9 KB | +5 install blocks |
| `omarchy-remove-browser` | 2.9 KB | +5 remove blocks |
| `omarchy-menu` | 34 KB | +15 browser entries across 3 menus |
| `omarchy-launch-webapp` | 0.9 KB | +6 browser patterns |

### Unchanged Files

These scripts already worked correctly with all browser types:

| File | Reason |
|------|--------|
| `omarchy-launch-browser` | Detects the private flag via `--help` (works for Chrome, Firefox, and all forks) |

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

- **💾 Persistence:** Patched files live in `~/.local/share/omarchy/bin/`, which
  is managed by the Omarchy git repository. Running `omarchy update` may
  overwrite them. Simply re-run `install.sh` after updates.

- **♻️ Restore:** The `restore.sh` script uses `git checkout` from the Omarchy
  repo — no separate backup files are needed. Original files are always one
  command away.

- **🔑 Default browser:** Omarchy ships with Chromium as the system default.
  This pack does not change that. Switch at any time with
  `omarchy default browser <name>`.

- **🎨 Icon glyphs:** Each browser uses a Nerd Font icon. Browsers sharing the
  same engine share the same icon family (e.g. all Firefox forks use `󰈹`).

- **🪟 Wayland:** Firefox-based browsers get `MOZ_ENABLE_WAYLAND=1` set via
  `~/.config/environment.d/omarchy-firefox-wayland.conf` at install time.

---

## 🔗 Links

| Project | Link |
|---------|------|
| Omarchy | [omarchy.org](https://omarchy.org/) |
| Helium Browser | [heliumbrowser.com](https://heliumbrowser.com/) |
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

Made for **Omarchy** · Arch Linux · Hyprland · Wayland

</div>
