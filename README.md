<div align="center">
  <h1>Omarchy Browser Support Pack</h1>
  <p><strong>Extended browser integration for Omarchy Linux</strong></p>
  <p>Install · Set as default · Launch · Web apps · Walker menu</p>
  <p><strong>12 browsers · 5 patched scripts · One-click setup</strong></p>
</div>

---

## Overview

Omarchy ships with Chromium as the default browser. This pack adds full
integration for 11 additional browsers — Chromium-based and Firefox-based alike.

Every browser gets:
- `omarchy default browser <name>` — set as system default
- `omarchy install browser <name>` — install from official repos or AUR
- `omarchy remove browser <name>` — clean removal with Chromium fallback
- `omarchy launch webapp <url>` — site-specific window support
- Walker menu entries under Setup > Defaults > Browser, Install > Browser,
  and Remove > Browser

---

## Supported Browsers

| # | Browser | Engine | Package | Source | Web Apps | Status |
|---|---------|--------|---------|--------|----------|--------|
| 1 | Chromium | Chromium | Pre-installed | — | `--app` | ✅ Default |
| 2 | Chrome | Chromium | `google-chrome` | AUR | `--app` | ✅ Existing |
| 3 | Brave | Chromium | `brave-bin` | AUR | `--app` | ✅ Existing |
| 4 | Brave Origin | Chromium | `brave-origin-beta-bin` | AUR | `--app` | ✅ Existing |
| 5 | Edge | Chromium | `microsoft-edge-stable-bin` | AUR | `--app` | ✅ Existing |
| 6 | **Vivaldi** | Chromium | `vivaldi` | **Official** | `--app` | 🆕 Added |
| 7 | **Helium** | Chromium | `helium-browser-bin` | AUR | `--app` | 🆕 Added |
| 8 | Firefox | Firefox | `firefox` | Official | `--new-window` | ✅ Existing |
| 9 | Zen | Firefox | `zen-browser-bin` | AUR | `--new-window` | ✅ Existing |
| 10 | **Floorp** | Firefox | `floorp-bin` | AUR | `--new-window` | 🆕 Added |
| 11 | **Waterfox** | Firefox | `waterfox-bin` | AUR | `--new-window` | 🆕 Added |
| 12 | **LibreWolf** | Firefox | `librewolf-bin` | AUR | `--new-window` | 🆕 Added |

---

## What This Pack Changes

Five Omarchy scripts are patched to recognize and handle the new browsers:

| Script | Purpose |
|--------|---------|
| `omarchy-default-browser` | Detects and sets the default browser via `xdg-settings` and `xdg-mime` |
| `omarchy-install-browser` | Installs a browser from official repos or AUR with managed policies |
| `omarchy-remove-browser` | Removes a browser, cleans up config, falls back to Chromium |
| `omarchy-menu` | Adds browser entries to the Walker menus (Setup/Install/Remove) |
| `omarchy-launch-webapp` | Launches a URL as a site-specific window using the correct flag per engine |

### Web App Behavior

| Engine | Flag | Example |
|--------|------|---------|
| Chromium-based (Chrome, Brave, Edge, Vivaldi, Helium, etc.) | `--app` | No UI chrome, standalone window |
| Firefox-based (Firefox, Zen, Floorp, Waterfox, LibreWolf) | `--new-window` | Opens in a normal browser window |
| Unknown / fallback | Chromium with `--app` | Falls back to Chromium |

Before this pack, Firefox and Zen web apps silently fell back to Chromium.
Now they use the user's preferred browser.

---

## Installation

### Prerequisites

- [Omarchy](https://omarchy.org/) (Arch Linux with Hyprland)
- Walker (default launcher, comes with Omarchy)
- `curl` (for one-click install)

### Option 1: One-Click Install (recommended)

```bash
bash <(curl -sL https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/install.sh)
omarchy restart walker
```

This downloads all 5 patched scripts, backs up the originals, and installs them.

### Option 2: Manual Install

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

### Option 3: Use Individual Browsers Without Patching

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

## Uninstall / Restore Originals

### Option 1: One-Click Restore

```bash
bash <(curl -sL https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/restore.sh)
omarchy restart walker
```

The restore script uses `git checkout` from the Omarchy repository at
`~/.local/share/omarchy/` to restore the original files. No backup files
are required — the git repo always has the pristine originals.

### Option 2: Manual Restore

```bash
cd ~/.local/share/omarchy
git checkout -- bin/omarchy-default-browser \
               bin/omarchy-install-browser \
               bin/omarchy-remove-browser \
               bin/omarchy-menu \
               bin/omarchy-launch-webapp
omarchy restart walker
```

### Option 3: Remove a Single Browser

```bash
# Remove the browser package and clean up
omarchy remove browser vivaldi
omarchy remove browser librewolf

# Reset default to Chromium if needed
omarchy default browser chromium
```

---

## Usage

### Set Default Browser

```bash
omarchy default browser              # Show current default
omarchy default browser vivaldi      # Set Vivaldi
omarchy default browser librewolf    # Set LibreWolf
omarchy default browser chromium     # Back to stock Chromium
```

### Launch Browser

```bash
omarchy launch browser                # Open default browser
omarchy launch browser https://x.com  # Open URL in default browser
omarchy launch webapp https://x.com   # Site-specific window
```

### Install / Remove

```bash
omarchy install browser vivaldi       # Install Vivaldi
omarchy install browser floorp        # Install Floorp
omarchy remove browser waterfox       # Remove Waterfox + cleanup
```

### Walker Menu

Press `SUPER+Space` and navigate:

```
Setup → Defaults → Browser  → (pick any of 12 browsers)
Install → Browser            → (pick any browser to install)
Remove → Browser             → (pick any browser to remove)
```

---

## Files

### Patched Scripts

All files live in `~/.local/share/omarchy/bin/`:

| File | Size | Lines Changed |
|------|------|---------------|
| `omarchy-default-browser` | 2.1 KB | +8 entries |
| `omarchy-install-browser` | 3.8 KB | +4 install blocks |
| `omarchy-remove-browser` | 2.9 KB | +4 remove blocks |
| `omarchy-menu` | 34 KB | +12 browsers across 3 menus |
| `omarchy-launch-webapp` | 803 B | +4 browser patterns |

### Unchanged Files

These scripts already worked correctly with all browser types:

| File | Reason |
|------|--------|
| `omarchy-launch-browser` | Detects private flag via `--help` (works for Chrome, Firefox, and all forks) |

---

## Browser Details

### Chromium-Based Browsers

| Browser | Desktop File | Executable | Private Flag | Policy Dir | Flags Config |
|---------|-------------|------------|-------------|------------|-------------|
| Chromium | `chromium.desktop` | `chromium` | `--incognito` | — | — |
| Chrome | `google-chrome.desktop` | `google-chrome-stable` | `--incognito` | `/etc/opt/chrome/policies/managed` | `~/.config/chrome-flags.conf` |
| Brave | `brave-browser.desktop` | `brave-browser` | `--incognito` | `/etc/brave/policies/managed` | `~/.config/brave-flags.conf` |
| Brave Origin | `brave-origin-beta.desktop` | `brave-origin-beta` | `--incognito` | `/etc/brave/policies/managed` | `~/.config/brave-origin-beta-flags.conf` |
| Edge | `microsoft-edge.desktop` | `microsoft-edge-stable` | `--inprivate` | `/etc/opt/edge/policies/managed` | `~/.config/microsoft-edge-stable-flags.conf` |
| **Vivaldi** | `vivaldi-stable.desktop` | `vivaldi-stable` | `--incognito` | `/etc/vivaldi/policies/managed` | `~/.config/vivaldi-flags.conf` |
| **Helium** | `helium.desktop` | `helium-browser` | `--incognito` | `/etc/helium/policies/managed` | `~/.config/helium-flags.conf` |

### Firefox-Based Browsers

| Browser | Desktop File | Executable | Private Flag | Distribution Dir |
|---------|-------------|------------|-------------|-----------------|
| Firefox | `firefox.desktop` | `firefox` | `--private-window` | `/usr/lib/firefox/distribution` |
| Zen | `zen.desktop` | `zen-browser` | `--private-window` | `/opt/zen-browser/distribution` |
| **Floorp** | `floorp.desktop` | `floorp` | `--private-window` | `/usr/lib/floorp/distribution` |
| **Waterfox** | `waterfox.desktop` | `waterfox` | `--private-window` | `/usr/lib/waterfox/distribution` |
| **LibreWolf** | `librewolf.desktop` | `librewolf` | `--private-window` | `/usr/lib/librewolf/distribution` |

---

## Notes

- **Persistence:** Patched files live in `~/.local/share/omarchy/bin/`, which
  is managed by the Omarchy git repository. Running `omarchy update` may
  overwrite them. Simply re-run `install.sh` after updates.

- **Restore:** The `restore.sh` script uses `git checkout` from the Omarchy
  repo — no separate backup files are needed. Original files are always one
  command away.

- **Default browser:** Omarchy ships with Chromium as the system default.
  This pack does not change that. Switch at any time with
  `omarchy default browser <name>`.

- **Icon glyphs:** Each browser uses a Nerd Font icon. Browsers sharing the
  same engine share the same icon family (e.g. all Firefox forks use `󰈹`).

- **Wayland:** Firefox-based browsers get `MOZ_ENABLE_WAYLAND=1` set via
  `~/.config/environment.d/omarchy-firefox-wayland.conf` at install time.

---

## Links

- [Omarchy](https://omarchy.org/)
- [Helium Browser](https://heliumbrowser.com/)
- [Vivaldi Browser](https://vivaldi.com/)
- [Floorp Browser](https://floorp.app/)
- [Waterfox Browser](https://www.waterfox.net/)
- [LibreWolf Browser](https://librewolf.net/)
- [AUR: helium-browser-bin](https://aur.archlinux.org/packages/helium-browser-bin)
- [AUR: floorp-bin](https://aur.archlinux.org/packages/floorp-bin)
- [AUR: waterfox-bin](https://aur.archlinux.org/packages/waterfox-bin)
- [AUR: librewolf-bin](https://aur.archlinux.org/packages/librewolf-bin)

---

<div align="center">
  <sub>Made for Omarchy · Arch Linux · Hyprland · Wayland</sub>
</div>
