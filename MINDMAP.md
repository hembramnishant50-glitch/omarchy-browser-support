```mermaid
mindmap
  root((Omarchy Browser<br/>Support Pack))
    Chromium_based
      Chromium["Pre-installed<br/>--app"]
      Chrome["AUR: google-chrome<br/>--app"]
      Brave["AUR: brave-bin<br/>--app"]
      Brave_Origin["AUR: brave-origin-beta-bin<br/>--app"]
      Edge["AUR: microsoft-edge-stable-bin<br/>--app"]
      Vivaldi["OFFICIAL: vivaldi ⬆ NEW<br/>--app"]
      Helium["AUR: helium-browser-bin ⬆ NEW<br/>--app"]
    Firefox_based
      Firefox["OFFICIAL: firefox<br/>--new-window ⬆ IMPROVED"]
      Zen["AUR: zen-browser-bin<br/>--new-window ⬆ IMPROVED"]
      Floorp["AUR: floorp-bin ⬆ NEW<br/>--new-window"]
      Waterfox["AUR: waterfox-bin ⬆ NEW<br/>--new-window"]
      LibreWolf["AUR: librewolf-bin ⬆ NEW<br/>--new-window"]
    Files_Patched
      default_browser["omarchy-default-browser<br/>12 browser detections"]
      install_browser["omarchy-install-browser<br/>9 install paths"]
      remove_browser["omarchy-remove-browser<br/>11 remove paths"]
      menu["omarchy-menu<br/>Setup/Install/Remove menus"]
      webapp["omarchy-launch-webapp<br/>Chromium --app / Firefox --new-window"]
```

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│  omarchy-default-browser                                 │
│  ┌──────────────┐  ┌────────────────┐  ┌─────────────┐  │
│  │ 12 browsers  │─→│ xdg-settings   │─→│ notify-send │  │
│  │ detected via │  │ xdg-mime       │  │ "X is now   │  │
│  │ desktop file │  │ (http/https/   │  │  default"   │  │
│  │              │  │  text/html)    │  │             │  │
│  └──────────────┘  └────────────────┘  └─────────────┘  │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│  omarchy-launch-webapp                                   │
│                                                          │
│  chromium/*/helium* ──→ --app "$url" ──→ uwsm-app exec   │
│  firefox/zen/floorp/waterfox/librewolf ──→ --new-window  │
│  anything else ──→ chromium --app (fallback)              │
└──────────────────────────────────────────────────────────┘

## Walker Menu

```
SUPER+Space
├── Setup → Defaults → Browser
│   ├── Chromium ◄── default
│   ├── Chrome / Brave / Brave Origin / Edge
│   ├── Vivaldi ◄── NEW
│   ├── Firefox / Zen / Helium
│   ├── Floorp / Waterfox ◄── NEW
│   └── LibreWolf ◄── NEW
├── Install → Browser
│   └── (all 12 browsers listed)
└── Remove → Browser
│   └── (all 12 browsers listed)
```

## Restore Flow

```
restore.sh:
  cd ~/.local/share/omarchy
  git checkout -- bin/omarchy-*
  # No backups needed — git always has originals
```
