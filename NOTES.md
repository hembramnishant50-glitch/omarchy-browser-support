# Technical Notes — Omarchy Browser Support Pack

## Overview

Patches 4 Omarchy scripts to add support for **Vivaldi, Helium, Floorp,
Waterfox, and LibreWolf** browsers, plus improved web app handling for
Firefox and Zen. Installs a Quickshell menu extension for browser entries.

Total of **12 browsers** supported across all menus and commands.

---

## Script Changes

### `omarchy-default-browser`

Detects and sets the default browser via `xdg-settings` + `xdg-mime`.

**Added lines (detection):**
- `vivaldi-stable.desktop` → `"vivaldi"`
- `helium.desktop` → `"helium"`
- `floorp.desktop` → `"floorp"`
- `waterfox.desktop` → `"waterfox"`
- `librewolf.desktop` → `"librewolf"`

**Added lines (set):**
- `vivaldi` → `vivaldi-stable.desktop` / `"Vivaldi"` / ``
- `helium` → `helium.desktop` / `"Helium"` / `󰀘`
- `floorp` → `floorp.desktop` / `"Floorp"` / `󰈹`
- `waterfox` → `waterfox.desktop` / `"Waterfox"` / `󰈹`
- `librewolf` → `librewolf.desktop` / `"LibreWolf"` / `󰈹`

### `omarchy-install-browser`

**Vivaldi** (Chromium, official repo): `omarchy-pkg-add vivaldi`
| Policy: `/etc/vivaldi/policies/managed` | Flags: `~/.config/vivaldi-flags.conf` | Theme applied

**Helium** (Chromium, AUR): `omarchy-pkg-aur-add helium-browser-bin`
| Policy: `/etc/helium/policies/managed` | Flags: `~/.config/helium-flags.conf`

**Floorp** (Firefox fork, AUR): `omarchy-pkg-aur-add floorp-bin`
| Distribution: `/usr/lib/floorp/distribution` | Wayland env

**Waterfox** (Firefox fork, AUR): `omarchy-pkg-aur-add waterfox-bin`
| Distribution: `/usr/lib/waterfox/distribution` | Wayland env

**LibreWolf** (Firefox fork, AUR): `omarchy-pkg-aur-add librewolf-bin`
| Distribution: `/usr/lib/librewolf/distribution` | Wayland env

### `omarchy-remove-browser`

Each new browser:
- Calls `set_fallback_default_browser` (reverts to Chromium if was default)
- Drops package via `omarchy-pkg-drop`
- Removes flags config and policy files (Chromium-based only)

### `omarchy-launch-webapp`

| Pattern | Flag | Before | After |
|---------|------|--------|-------|
| `chromium*`, `google-chrome*`, `brave*`, `microsoft-edge*`, `opera*`, `vivaldi*`, `helium*` | `--app` | ✅ Works | ✅ Works |
| `firefox*`, `zen*`, `floorp*`, `waterfox*`, `librewolf*` | `--new-window` | ❌ Chromium fallback | ✅ Uses native browser |
| anything else | Chromium `--app` | ✅ Fallback | ✅ Fallback |

---

## Quickshell Menu Extension

### `omarchy-browser-menu.jsonc`

JSONC menu extension installed to `~/.config/omarchy/extensions/`. Uses the
dotted-ID convention to add entries to existing menus:

| Entry | Purpose |
|-------|---------|
| `setup.default.browser.vivaldi` | Vivaldi default browser option (with `when`/`checked`) |
| `setup.default.browser.helium` | Helium default browser option |
| `setup.default.browser.floorp` | Floorp default browser option |
| `setup.default.browser.waterfox` | Waterfox default browser option |
| `setup.default.browser.librewolf` | LibreWolf default browser option |
| `install.browser.*` | Install browser entries |
| `remove.browser.*` | Remove browser entries |

Each entry uses `when` to check if the browser command exists, `checked` to
show the current default, and `action` to run the appropriate command.

---

## Full Browser Reference

| Browser | Desktop File | Package | Source | Engine | Web App |
|---------|-------------|---------|--------|--------|---------|
| Chromium | `chromium.desktop` | Pre-installed | — | Chromium | `--app` |
| Chrome | `google-chrome.desktop` | `google-chrome` | AUR | Chromium | `--app` |
| Brave | `brave-browser.desktop` | `brave-bin` | AUR | Chromium | `--app` |
| Brave Origin | `brave-origin-beta.desktop` | `brave-origin-beta-bin` | AUR | Chromium | `--app` |
| Edge | `microsoft-edge.desktop` | `microsoft-edge-stable-bin` | AUR | Chromium | `--app` |
| **Vivaldi** | `vivaldi-stable.desktop` | `vivaldi` | Official | Chromium | `--app` |
| **Helium** | `helium.desktop` | `helium-browser-bin` | AUR | Chromium | `--app` |
| Firefox | `firefox.desktop` | `firefox` | Official | Firefox | `--new-window` |
| Zen | `zen.desktop` | `zen-browser-bin` | AUR | Firefox | `--new-window` |
| **Floorp** | `floorp.desktop` | `floorp-bin` | AUR | Firefox | `--new-window` |
| **Waterfox** | `waterfox.desktop` | `waterfox-bin` | AUR | Firefox | `--new-window` |
| **LibreWolf** | `librewolf.desktop` | `librewolf-bin` | AUR | Firefox | `--new-window` |

---

## Installation Paths

### Package-Based (Omarchy Quattro)

Scripts installed to `/usr/bin/` (requires sudo).
Menu extension installed to `~/.config/omarchy/`.

### Git-Based (Legacy)

Scripts installed to `~/.local/share/omarchy/bin/`.
Menu extension installed to `~/.config/omarchy/`.

---

## Restore

The `restore.sh` script:
1. Restores scripts from `/usr/share/omarchy/bin/` or git repo
2. Removes browser menu extension from `~/.config/omarchy/extensions/`
3. Cleans up `.bak` files

Alternatively, `sudo pacman -S omarchy` reinstalls all original scripts.
