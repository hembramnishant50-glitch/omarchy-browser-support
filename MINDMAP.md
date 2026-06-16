```mermaid
mindmap
  root((Omarchy Browser<br/>Integration))
    Helium
      install["omarchy install browser helium<br/>AUR: helium-browser-bin"]
      default["omarchy default browser helium<br/>xdg-settings + xdg-mime"]
      remove["omarchy remove browser helium<br/>cleanup + Chromium fallback"]
      webapp["omarchy launch webapp → --app mode"]
      menu["Walker: Setup/Install/Remove menus"]
    Firefox
      install["omarchy install browser firefox<br/>(already supported)"]
      default["omarchy default browser firefox<br/>(already supported)"]
      webapp["omarchy launch webapp → --new-window<br/>⬆ NEW: was Chromium fallback"]
    Zen
      install["omarchy install browser zen<br/>(already supported)"]
      default["omarchy default browser zen<br/>(already supported)"]
      webapp["omarchy launch webapp → --new-window<br/>⬆ NEW: was Chromium fallback"]
    Files_Patched
      db["omarchy-default-browser<br/>+helium detection + set"]
      ib["omarchy-install-browser<br/>+AUR + policy + flags"]
      rb["omarchy-remove-browser<br/>+remove + cleanup + fallback"]
      menu["omarchy-menu<br/>+3 submenu entries"]
      wa["omarchy-launch-webapp<br/>+firefox/zen dispatch"]
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     omarchy-default-browser              │
│  detect ──→ xdg-settings set ──→ xdg-mime ──→ notify   │
│  helium.desktop    default-web-browser  http/https/html  │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                     omarchy-install-browser              │
│  helium-browser-bin (AUR)                                │
│    ├── /etc/helium/policies/managed/                     │
│    └── ~/.config/helium-flags.conf                       │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                     omarchy-remove-browser               │
│  omarchy-pkg-drop helium-browser-bin                     │
│    ├── rm ~/.config/helium-flags.conf                    │
│    ├── sudo rm /etc/helium/policies/managed/color.json   │
│    └── fallback → chromium if was default                │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                     omarchy-launch-webapp                │
│  ┌──────────┐  ┌──────────────┐  ┌───────────────────┐  │
│  │ chromium │─→│ --app "$url" │─→│ uwsm-app exec     │  │
│  │ helium   │─→│ --app "$url" │─→│ uwsm-app exec     │  │
│  │ firefox  │─→│ --new-window │─→│ uwsm-app exec     │  │
│  │ zen      │─→│ --new-window │─→│ uwsm-app exec     │  │
│  │ other    │─→│ chromium     │─→│ uwsm-app exec     │  │
│  └──────────┘  └──────────────┘  └───────────────────┘  │
└─────────────────────────────────────────────────────────┘

## Walker Menu Flow

```
SUPER+Space
├── Setup
│   └── Defaults
│       └── Browser
│           ├── Chromium ◄── default
│           ├── Chrome
│           ├── Brave
│           ├── Brave Origin
│           ├── Edge
│           ├── Firefox
│           ├── Zen
│           └── Helium   ◄── NEW
├── Install
│   └── Browser
│       └── Helium       ◄── NEW
└── Remove
    └── Browser
        └── Helium       ◄── NEW
```

## Install / Restore Flow

```
install.sh:
  Download 5 files from GitHub
  Backup originals → {file}.bak.{timestamp}
  Copy patched files → ~/.local/share/omarchy/bin/
  Message: "Done! omarchy restart walker"

restore.sh:
  Find latest .bak for each file
  Copy .bak back → ~/.local/share/omarchy/bin/{file}
  Remove .bak files
  Message: "Done! omarchy restart walker"
```
