# Omarchy Browser Support Pack

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Platform: Arch Linux](https://img.shields.io/badge/Platform-Arch%20Linux-blue.svg)](https://archlinux.org/)
[![Desktop: Omarchy Quattro](https://img.shields.io/badge/Desktop-Omarchy%20Quattro-purple.svg)](https://omarchy.org/)

Adds **Vivaldi, Helium, Floorp, Waterfox, and LibreWolf** to the [Omarchy](https://omarchy.org/) desktop menu — with one-click install, set-as-default, and remove support.

> **Stock Omarchy** already ships scripts that support all 12 browsers. This pack only adds the **missing menu entries** via a Quickshell JSONC extension. No script patching required.

---

## Features

- **Menu Integration** — 5 extra browsers appear in Setup, Install, and Remove menus
- **Smart Visibility** — entries show/hide based on whether the browser is installed
- **One-Click Install** — click a browser in the menu to install it
- **Browser Picker** — "Install Browser" opens a selector to pick one
- **Set as Default** — select any installed browser as your default via Setup > Defaults > Browser
- **Clean Uninstall** — one command to remove everything

---

## Supported Browsers

| Browser | Source | Package | Command |
|---------|--------|---------|---------|
| Vivaldi | Official repo | `vivaldi` | `vivaldi-stable` |
| Helium | AUR | `helium-browser-bin` | `helium-browser` |
| Floorp | AUR | `floorp-bin` | `floorp` |
| Waterfox | AUR | `waterfox-bin` | `waterfox` |
| LibreWolf | AUR | `librewolf-bin` | `librewolf` |

---

## Install

```bash
git clone https://github.com/hembramnishant50-glitch/omarchy-browser-support.git
cd omarchy-browser-support
bash install.sh
```

Or one-liner:

```bash
bash <(curl -sL https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/install.sh)
```

### What it does

1. Installs `omarchy-browser-menu.jsonc` to `~/.config/omarchy/extensions/`
2. Installs `omarchy-browser-select` and `omarchy-browser-select-remove` to `~/.local/bin/`
3. Runs `omarchy menu refresh`

---

## Uninstall

```bash
cd omarchy-browser-support
bash restore.sh
```

Or one-liner:

```bash
bash <(curl -sL https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/restore.sh)
```

### Manual Uninstall

```bash
rm ~/.config/omarchy/extensions/omarchy-browser-menu.jsonc
rm ~/.local/bin/omarchy-browser-select ~/.local/bin/omarchy-browser-select-remove
omarchy menu refresh
```

---

## Menu Entries

### Install > Browser

| Entry | Action |
|-------|--------|
| **Install Browser** | Opens a picker to select and install a browser |
| Vivaldi | Installs Vivaldi (hidden if already installed) |
| Helium | Installs Helium (hidden if already installed) |
| Floorp | Installs Floorp (hidden if already installed) |
| Waterfox | Installs Waterfox (hidden if already installed) |
| LibreWolf | Installs LibreWolf (hidden if already installed) |

### Setup > Defaults > Browser

| Entry | Action |
|-------|--------|
| Vivaldi | Sets Vivaldi as default (shows only if installed) |
| Helium | Sets Helium as default (shows only if installed) |
| Floorp | Sets Floorp as default (shows only if installed) |
| Waterfox | Sets Waterfox as default (shows only if installed) |
| LibreWolf | Sets LibreWolf as default (shows only if installed) |

### Remove > Browser

| Entry | Action |
|-------|--------|
| **Remove Browser** | Opens a picker to select and remove a browser |
| Vivaldi | Removes Vivaldi (shown only if installed) |
| Helium | Removes Helium (shown only if installed) |
| Floorp | Removes Floorp (shown only if installed) |
| Waterfox | Removes Waterfox (shown only if installed) |
| LibreWolf | Removes LibreWolf (shown only if installed) |

---

## How It Works

The pack uses Quickshell's **dotted-ID JSONC extension** format to merge entries into the stock Omarchy menu:

```
omarchy-browser-menu.jsonc
├── setup.default.browser.*    →  adds to Setup > Defaults > Browser
├── install.browser.*          →  adds to Install > Browser
└── remove.browser.*           →  adds to Remove > Browser
```

Each entry defines:
- `when` — shell condition to show/hide the entry
- `checked` — shell condition for a checkmark (defaults only)
- `action` — command to run on click

The selector scripts (`omarchy-browser-select`, `omarchy-browser-select-remove`) present a numbered menu in a floating terminal to pick which browser to install or remove.

---

## Compatibility

| Requirement | Status |
|-------------|--------|
| Omarchy Quattro (Quickshell) | Supported |
| Omarchy Classic (Walker) | Not supported |
| Package-based install | Supported |
| Git-based install | Supported |
| Arch Linux | Required |

---

## File Structure

```
omarchy-browser-support/
├── install.sh                    # Installer script
├── restore.sh                    # Uninstaller script
├── omarchy-browser-menu.jsonc    # Quickshell menu extension
├── omarchy-browser-select        # Interactive browser installer picker
├── omarchy-browser-select-remove # Interactive browser remover picker
└── README.md                     # This file
```

---

## License

MIT
