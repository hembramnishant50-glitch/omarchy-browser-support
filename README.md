# Omarchy Browser Support Pack

![Omarchy](https://img.shields.io/badge/Omarchy-Quattro-purple?style=for-the-badge&logo=archlinux)
![Shell](https://img.shields.io/badge/Shell-Quickshell-blue?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

> **Adds 5 privacy-focused browsers to Omarchy Quattro menu with one-click install, set-as-default, and remove support.**

| Browser | Icon | Source | Description |
|---------|------|--------|-------------|
| **Vivaldi** | 󰀙 | Official Repo | Highly customizable, built-in ad blocker, mail client |
| **Helium** | 󰀘 | AUR | Lightweight Chromium fork, minimal UI |
| **Floorp** | 󰈹 | AUR | Firefox-based, Japanese development, privacy-focused |
| **Waterfox** | 󰈹 | AUR | Firefox fork, no telemetry, legacy extension support |
| **LibreWolf** | 󰈹 | AUR | Firefox fork, hardened privacy & security out of the box |

---

## 🚀 Quick Install

### One-liner (curl)
```bash
bash <(curl -sL https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/install.sh)
```

### From cloned repo
```bash
git clone https://github.com/hembramnishant50-glitch/omarchy-browser-support.git
cd omarchy-browser-support
bash install.sh
```

---

## 📋 What Gets Installed

| Component | Location | Description |
|-----------|----------|-------------|
| Menu Extension | `~/.config/omarchy/extensions/omarchy-menu.jsonc` | Adds browsers to Setup/Install/Remove menus |
| Browser Selector | `~/.local/bin/omarchy-browser-select` | Interactive picker to install one browser |
| Browser Remover | `~/.local/bin/omarchy-browser-select-remove` | Interactive picker to remove one browser |
| Individual Installers | `~/.local/bin/install-<browser>` | Install specific browser directly |
| Individual Removers | `~/.local/bin/remove-<browser>` | Remove specific browser directly |

---

## 🎯 Menu Integration

After install, open the Omarchy menu (`Super` key) and navigate:

```
Setup ▸ Defaults ▸ Browser
    ├── 󰀙 Vivaldi
    ├── 󰀘 Helium
    ├── 󰈹 Floorp
    ├── 󰈹 Waterfox
    └── 󰈹 LibreWolf
    (only shows if browser is installed)

Install ▸ Browser
    ├── 󰀙 Vivaldi
    ├── 󰀘 Helium
    ├── 󰈹 Floorp
    ├── 󰈹 Waterfox
    ├── 󰈹 LibreWolf
    (only shows if NOT installed)
    └── 󰉉 Install Browser  (interactive picker)

Remove ▸ Browser
    ├── 󰀙 Vivaldi
    ├── 󰀘 Helium
    ├── 󰈹 Floorp
    ├── 󰈹 Waterfox
    ├── 󰈹 LibreWolf
    (only shows if installed)
    └── 󰭌 Remove Browser  (interactive picker)
```

---

## ⌨️ Direct Commands

### Install a specific browser
```bash
install-helium        # Install Helium
install-vivaldi       # Install Vivaldi
install-floorp        # Install Floorp
install-waterfox      # Install Waterfox
install-librewolf     # Install LibreWolf
```

### Remove a specific browser
```bash
remove-helium         # Remove Helium
remove-vivaldi        # Remove Vivaldi
remove-floorp         # Remove Floorp
remove-waterfox       # Remove Waterfox
remove-librewolf      # Remove LibreWolf
```

### Interactive pickers
```bash
omarchy-browser-select          # Pick & install one browser
omarchy-browser-select-remove   # Pick & remove one browser
```

---

## 🗑️ Uninstall

```bash
bash restore.sh
# or
bash <(curl -sL https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/restore.sh)
```

---

## 🔧 How It Works

1. **No script patching needed** — Stock Omarchy scripts already support all 12 browsers
2. **JSONC Menu Extension** — Uses Quickshell's dotted-ID format to merge into existing menus
3. **Smart Visibility** — Entries auto-show/hide based on package installation status
4. **Native Integration** — Uses `omarchy-install-browser` / `omarchy-remove-browser` / `omarchy-default-browser`

---

## 📦 Supported Browsers (12 Total)

| Browser | Package | Status |
|---------|---------|--------|
| Chromium | `chromium` | ✅ Stock |
| Chrome | `google-chrome` (AUR) | ✅ Stock |
| Brave | `brave-bin` (AUR) | ✅ Stock |
| Brave Origin | `brave-origin-bin` (AUR) | ✅ Stock |
| Edge | `microsoft-edge-stable-bin` (AUR) | ✅ Stock |
| **Vivaldi** | `vivaldi` | ✅ **This Pack** |
| Firefox | `firefox` | ✅ Stock |
| Zen | `zen-browser-bin` (AUR) | ✅ Stock |
| **Helium** | `helium-browser-bin` (AUR) | ✅ **This Pack** |
| **Floorp** | `floorp-bin` (AUR) | ✅ **This Pack** |
| **Waterfox** | `waterfox-bin` (AUR) | ✅ **This Pack** |
| **LibreWolf** | `librewolf-bin` (AUR) | ✅ **This Pack** |

---

## 🛠️ Requirements

- **Omarchy Quattro** (Quickshell-based)
- **Arch Linux** with `yay` or `paru` for AUR packages
- `omarchy` command available in PATH

---

## 📄 License

MIT License — See [LICENSE](LICENSE) for details

---

## 🙏 Credits

Built for [Omarchy](https://omarchy.org/) by [Nishant Hembram](https://github.com/hembramnishant50-glitch)

---

<div align="center">

[⬆ Back to Top](#omarchy-browser-support-pack) • [🐛 Report Bug](https://github.com/hembramnishant50-glitch/omarchy-browser-support/issues) • [✨ Request Feature](https://github.com/hembramnishant50-glitch/omarchy-browser-support/issues)

</div>