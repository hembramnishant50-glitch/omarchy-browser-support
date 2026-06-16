# Technical Notes — Omarchy Browser Support Pack

## Overview

Patches 5 Omarchy scripts under `~/.local/share/omarchy/bin/` to add support for
**Vivaldi, Helium, Floorp, Waterfox, and LibreWolf** browsers, plus improved
web app handling for Firefox and Zen.

Total of **12 browsers** supported across all menus and commands.

---

## Script Changes

### `omarchy-default-browser`

Detects and sets the default browser via `xdg-settings` + `xdg-mime`.

**Added lines (detection):**
- `vivaldi-stable.desktop` → `"vivaldi"`
- `floorp.desktop` → `"floorp"`
- `waterfox.desktop` → `"waterfox"`
- `librewolf.desktop` → `"librewolf"`

**Added lines (set):**
- `vivaldi` → `vivaldi-stable.desktop` / `"Vivaldi"` / ``
- `floorp` → `floorp.desktop` / `"Floorp"` / `󰈹`
- `waterfox` → `waterfox.desktop` / `"Waterfox"` / `󰈹`
- `librewolf` → `librewolf.desktop` / `"LibreWolf"` / `󰈹`

### `omarchy-install-browser`

**Vivaldi** (Chromium, official repo): `omarchy-pkg-add vivaldi`
| Policy: `/etc/vivaldi/policies/managed` | Flags: `~/.config/vivaldi-flags.conf` | Theme applied

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

### `omarchy-menu`

Three functions updated with all 12 browsers:

| Function | Browsers listed |
|----------|----------------|
| `show_setup_default_browser_menu` | All 12 (auto-detected via desktop file) |
| `show_install_browser_menu` | All 12 install options |
| `show_remove_browser_menu` | All 12 remove options |

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

## Restore

The `restore.sh` script uses `git checkout` from the Omarchy repo at
`~/.local/share/omarchy/` — no backup files required.
