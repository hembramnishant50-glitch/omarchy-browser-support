# Technical Notes — Browser Integration

## Overview

Patched 5 Omarchy scripts under `~/.local/share/omarchy/bin/` to add Helium browser
support and improve Firefox/Zen web app handling.

### Script: `omarchy-default-browser`

**Purpose:** Get/set the default browser via `xdg-settings` + `xdg-mime`.

**Added:**
- Line 16: detect `helium.desktop` → output `"helium"`
- Line 30: map `helium` → `helium.desktop` / `"Helium"` / glyph `󰀘`
- Line 32: usage string updated to include `|helium`

**Behavior:**
- No args → reads current default from `xdg-settings`
- With `helium` → runs `xdg-settings set`, `xdg-mime` for http/https/text/html
- Sends notification: `󰀘    Helium is now the default browser`

### Script: `omarchy-install-browser`

**Purpose:** Install a browser with Omarchy's managed policies and theming.

**Added (lines 89-96):**
- AUR package: `helium-browser-bin`
- Policy directory: `/etc/helium/policies/managed`
- Chromium flags: `~/.config/helium-flags.conf`
- Pattern matches Chrome/Brave/Edge (all Chromium forks)

### Script: `omarchy-remove-browser`

**Purpose:** Remove a browser, clean up config, fallback to Chromium.

**Added (lines 69-75):**
- Drops package, removes flags + policy files
- Falls back to Chromium via `set_fallback_default_browser` if Helium was default

### Script: `omarchy-menu`

**Purpose:** Walker menu system (Setup/Install/Remove submenus).

**Modified 3 functions:**

| Function | Lines | Change |
|----------|-------|--------|
| `show_setup_default_browser_menu` | 368-402 | Detect `helium.desktop`, show in list, preselect if default, handle selection |
| `show_install_browser_menu` | 520-531 | Add `󰀘  Helium` entry → `omarchy-install-browser helium` |
| `show_remove_browser_menu` | 691-702 | Add `󰀘  Helium` entry → `omarchy-remove-browser helium` |

### Script: `omarchy-launch-webapp`

**Purpose:** Open a URL as a site-specific browser window.

**Changed:** Complete rewrite of the dispatch logic.

| Browser Type | Flag | Before | After |
|-------------|------|--------|-------|
| Chromium-based | `--app` | ✅ Worked | ✅ Worked |
| Helium | `--app` | ❌ Fell back to Chromium | ✅ Uses Helium directly |
| Firefox | `--new-window` | ❌ Fell back to Chromium | ✅ Uses Firefox directly |
| Zen | `--new-window` | ❌ Fell back to Chromium | ✅ Uses Zen directly |
| Unknown | `--app` with Chromium | ✅ Fallback | ✅ Fallback (same) |

---

## File Inventory

```
~/.local/share/omarchy/bin/
├── omarchy-default-browser    (patched)
├── omarchy-install-browser    (patched)
├── omarchy-remove-browser     (patched)
├── omarchy-menu               (patched)
├── omarchy-launch-webapp      (patched)
├── omarchy-launch-browser     (unchanged — already works)
```

## Backup Files

The `install.sh` creates backups named `{file}.bak.{timestamp}`.

To restore: `bash restore.sh` or manually `cp {file}.bak.{timestamp} {file}`.
