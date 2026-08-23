# Omarchy Browser Support Pack — Technical Notes

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      OMARCHY QUATTRO                            │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   QUICKSHELL MENU                       │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │   │
│  │  │   SETUP      │  │   INSTALL    │  │   REMOVE     │  │   │
│  │  │  Defaults    │  │   Browser    │  │   Browser    │  │   │
│  │  │   ▼          │  │   ▼          │  │   ▼          │  │   │
│  │  │  Browser     │  │  Vivaldi     │  │  Vivaldi     │  │   │
│  │  │  ▸ Vivaldi   │  │  Helium      │  │  Helium      │  │   │
│  │  │  ▸ Helium    │  │  Floorp      │  │  Floorp      │  │   │
│  │  │  ▸ Floorp    │  │  Waterfox    │  │  Waterfox    │  │   │
│  │  │  ▸ Waterfox  │  │  LibreWolf   │  │  LibreWolf   │  │   │
│  │  │  ▸ Waterfox  │  │  ▸ Pick One  │  │  ▸ Pick One  │  │   │
│  │  │  ▸ LibreWolf │  │              │  │              │  │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    EXTENSION LOADING                            │
│  /usr/share/omarchy/default/omarchy/omarchy-menu.jsonc (base)  │
│  ~/.config/omarchy/extensions/omarchy-menu.jsonc (user)        │
│  → Merged on per-key basis in MenuModel.mergeMenuSources()     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    STOCK SCRIPTS (Unmodified)                   │
│  /usr/bin/omarchy-default-browser    → Sets XDG defaults       │
│  /usr/bin/omarchy-install-browser    → Installs + policies     │
│  /usr/bin/omarchy-remove-browser     → Removes + fallback      │
│  /usr/bin/omarchy-launch-webapp      → Launches web apps       │
└─────────────────────────────────────────────────────────────────┘
```

## Key Design Decisions

### 1. No Script Patching
Stock Omarchy scripts already support all 12 browsers. This pack only adds **menu entries** via JSONC extension.

### 2. Single Extension File
Quickshell only loads `~/.config/omarchy/extensions/omarchy-menu.jsonc`. No separate files.

### 3. Dotted-ID Convention
Entries use dotted IDs (`setup.default.browser.vivaldi`) which Quickshell merges into parent menus automatically.

### 4. Smart Visibility (`when` field)
```json
"when": "omarchy-cmd-present vivaldi-stable"        // Show in Setup if installed
"when": "! omarchy-pkg-present vivaldi"             // Show in Install if NOT installed
"when": "omarchy-pkg-present vivaldi"               // Show in Remove if installed
```

### 5. Checked State (`checked` field)
```json
"checked": "[[ \"$(omarchy-default-browser)\" == \"vivaldi\" ]]"
```
Shows ✓ next to current default browser.

## File Structure

```
omarchy-browser-support/
├── install.sh                    # Main installer (curl-friendly)
├── restore.sh                    # Complete uninstaller
├── omarchy-menu.jsonc            # Menu extension (15 entries)
├── omarchy-browser-select        # Interactive installer picker
├── omarchy-browser-select-remove # Interactive remover picker
├── install-helium.sh             # Direct Helium installer
├── install-vivaldi.sh            # Direct Vivaldi installer
├── install-floorp.sh             # Direct Floorp installer
├── install-waterfox.sh           # Direct Waterfox installer
├── install-librewolf.sh          # Direct LibreWolf installer
├── remove-helium.sh              # Direct Helium remover
├── remove-vivaldi.sh             # Direct Vivaldi remover
├── remove-floorp.sh              # Direct Floorp remover
├── remove-waterfox.sh            # Direct Waterfox remover
├── remove-librewolf.sh           # Direct LibreWolf remover
├── README.md                     # Documentation
├── MINDMAP.md                    # Architecture diagram
└── NOTES.md                      # This file
```

## JSONC Entry Format

Each menu entry follows Quickshell's normalized item structure:

```json
{
  "id": "setup.default.browser.vivaldi",
  "parent": "setup.default.browser",
  "kind": "action",
  "icon": "󰀙",
  "label": "Vivaldi",
  "action": "omarchy-default-browser vivaldi",
  "when": "omarchy-cmd-present vivaldi-stable",
  "checked": "[[ \"$(omarchy-default-browser)\" == \"vivaldi\" ]]",
  "order": 0
}
```

## Browser Commands Reference

| Browser | Command | Desktop File | Package | AUR Package |
|---------|---------|--------------|---------|-------------|
| Vivaldi | `vivaldi-stable` | `vivaldi-stable.desktop` | `vivaldi` | - |
| Helium | `helium-browser` | `helium.desktop` | - | `helium-browser-bin` |
| Floorp | `floorp` | `floorp.desktop` | - | `floorp-bin` |
| Waterfox | `waterfox` | `waterfox.desktop` | - | `waterfox-bin` |
| LibreWolf | `librewolf` | `librewolf.desktop` | - | `librewolf-bin` |

## Stock Menu Defaults (Already Present)

The stock `/usr/share/omarchy/default/omarchy/omarchy-menu.jsonc` already has:
- `setup.default.browser.chromium`
- `setup.default.browser.chrome`
- `setup.default.browser.brave`
- `setup.default.browser.brave-origin`
- `setup.default.browser.edge`
- `setup.default.browser.firefox`
- `setup.default.browser.zen`
- `install.browser.chrome`
- `install.browser.edge`
- `install.browser.brave`
- `install.browser.brave-origin`
- `install.browser.firefox`
- `install.browser.zen`
- `remove.browser.chrome`
- `remove.browser.edge`
- `remove.browser.brave`
- `remove.browser.brave-origin`
- `remove.browser.firefox`
- `remove.browser.zen`

This pack adds the 5 missing browsers to each section.

## Installation Flow

```
User runs: bash install.sh
    │
    ├── Downloads omarchy-menu.jsonc from GitHub (or uses local)
    ├── Backs up existing ~/.config/omarchy/extensions/omarchy-menu.jsonc
    ├── Copies new omarchy-menu.jsonc to ~/.config/omarchy/extensions/
    ├── Downloads/copies 12 helper scripts to ~/.local/bin/
    │   ├── omarchy-browser-select
    │   ├── omarchy-browser-select-remove
    │   ├── install-helium, install-vivaldi, install-floorp, install-waterfox, install-librewolf
    │   └── remove-helium, remove-vivaldi, remove-floorp, remove-waterfox, remove-librewolf
    ├── Makes all scripts executable
    └── Runs: omarchy menu refresh
```

## Uninstallation Flow

```
User runs: bash restore.sh
    │
    ├── Finds latest backup: ~/.config/omarchy/extensions/omarchy-menu.jsonc.bak.*
    ├── If backup exists: restores it
    ├── If no backup: removes the extension file
    ├── Removes all 12 helper scripts from ~/.local/bin/
    └── Runs: omarchy menu refresh
```

## Quickshell Menu Internals

From `/usr/share/omarchy/shell/plugins/menu/Menu.qml`:

```qml
property string userMenuPath: Quickshell.env("HOME") + "/.config/omarchy/extensions/omarchy-menu.jsonc"

FileView {
  id: userMenuFile
  path: root.userMenuPath
  watchChanges: true
  onLoaded: { root.userMenuItems = root.parseMenuJsonc(text()); root.rebuildItemsFromSources() }
  onLoadFailed: { root.userMenuItems = []; root.rebuildItemsFromSources() }
}
```

The merge happens in `MenuModel.mergeMenuSources(defaultMenuItems, userMenuItems)` — later entries override earlier ones on a per-key basis.

## Guard Evaluation

`when:` and `checked:` conditions are evaluated in batch:

```qml
function evaluateGuards() {
  var script = MenuModel.guardScript(root.items)
  guardProc.command = ["bash", "-lc", script]
  guardProc.running = true
}
```

Results are parsed as `id:w:true/false` for `when` and `id:c:true/false` for `checked`.

## Provider System (Not Used Here)

Quickshell supports dynamic providers (e.g., fonts, power-profiles) via bash scripts that output tab-separated rows. This pack uses **static entries** instead — simpler and faster.

## Testing Commands

```bash
# Test menu extension syntax
jq empty ~/.config/omarchy/extensions/omarchy-menu.jsonc

# Test individual entries
omarchy-cmd-present vivaldi-stable && echo "Vivaldi installed"
omarchy-pkg-present vivaldi && echo "Vivaldi package installed"
omarchy-default-browser vivaldi

# Refresh menu
omarchy menu refresh

# Test picker scripts
omarchy-browser-select
omarchy-browser-select-remove

# Test direct install/remove
install-vivaldi
remove-vivaldi
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Menu entries not showing | Run `omarchy menu refresh` or restart shell: `omarchy restart shell` |
| Vivaldi icon not showing | Ensure Nerd Font is installed; icon is `󰀙` (nf-md-alpha_v_box) |
| Install fails | Check AUR helper: `yay -Ss <package>` or `paru -Ss <package>` |
| Permission denied | Scripts in `~/.local/bin` need execute bit: `chmod +x ~/.local/bin/*` |
| Duplicate entries | Restore from backup: `bash restore.sh` then reinstall |

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2024-08-23 | Initial release with 5 browsers, menu extension, pickers |
| 1.1.0 | 2024-08-23 | Fixed to write to omarchy-menu.jsonc (only file Quickshell loads) |
| 1.2.0 | 2024-08-23 | Added individual install/remove scripts, improved README, MINDMAP, NOTES |

---

*Last updated: 2024-08-23*