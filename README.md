# Helium, Firefox & Zen Browser — Omarchy Integration

Add [Helium](https://heliumbrowser.com/) (Chromium fork), [Firefox](https://www.mozilla.org/firefox/), and [Zen](https://zen-browser.app/) (Firefox fork) support to Omarchy with full integration: install, set as default, launch, web apps, and Walker menu support.

---

## What's Added

| Browser | Install | Set Default | Web Apps | Menu Integration |
|---------|---------|-------------|----------|------------------|
| Helium  | `omarchy install browser helium` | `omarchy default browser helium` | `--app` mode | Setup > Defaults > Browser |
| Firefox | Already supported | Already supported | `--new-window` (was: Chromium fallback) | Already present |
| Zen     | Already supported | Already supported | `--new-window` (was: Chromium fallback) | Already present |

---

## Installation

### Option 1: One-Click (recommended)

```bash
bash <(curl -sL https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/install.sh)
omarchy restart walker
```

### Option 2: Step by Step

```bash
# 1. Download patched files
curl -LO https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/patches/omarchy-default-browser
curl -LO https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/patches/omarchy-install-browser
curl -LO https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/patches/omarchy-remove-browser
curl -LO https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/patches/omarchy-menu
curl -LO https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/patches/omarchy-launch-webapp
chmod +x omarchy-*

# 2. Backup originals
cp ~/.local/share/omarchy/bin/omarchy-default-browser{,.bak}
cp ~/.local/share/omarchy/bin/omarchy-install-browser{,.bak}
cp ~/.local/share/omarchy/bin/omarchy-remove-browser{,.bak}
cp ~/.local/share/omarchy/bin/omarchy-menu{,.bak}
cp ~/.local/share/omarchy/bin/omarchy-launch-webapp{,.bak}

# 3. Install patched versions
cp omarchy-* ~/.local/share/omarchy/bin/

# 4. Restart Walker
omarchy restart walker
```

### Option 3: Just Use Helium (no patching needed)

Skip patching entirely — Helium's basic `omarchy` commands already work out of the box:

```bash
omarchy install browser helium
omarchy default browser helium
```

Firefox and Zen work without patching too. Patching only improves `omarchy launch webapp` behavior.

---

## Uninstall / Restore Originals

### Option 1: One-Click Restore

```bash
bash <(curl -sL https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/restore.sh)
omarchy restart walker
```

### Option 2: Manual Restore

```bash
# Restore each backup file
for f in omarchy-default-browser omarchy-install-browser omarchy-remove-browser omarchy-menu omarchy-launch-webapp; do
  if [[ -f ~/.local/share/omarchy/bin/$f.bak ]]; then
    cp ~/.local/share/omarchy/bin/$f.bak ~/.local/share/omarchy/bin/$f
    echo "Restored $f"
  fi
done
omarchy restart walker
```

### Option 3: Remove Helium Completely

```bash
# Remove Helium browser
omarchy remove browser helium

# If Chromium isn't already default, set it
omarchy default browser chromium
```

---

## Usage

```bash
# Switch default browser
omarchy default browser              # Show current
omarchy default browser helium       # Set Helium
omarchy default browser chromium     # Back to Chromium

# Launch
omarchy launch browser                # Open default browser
omarchy launch browser https://x.com  # Open URL
omarchy launch webapp https://x.com   # Site-specific window

# Manage
omarchy install browser helium        # Install Helium
omarchy remove browser helium         # Remove Helium + cleanup
```

### Walker Menu

```
SUPER+Space → Setup → Defaults → Browser → Helium
SUPER+Space → Install → Browser → Helium
SUPER+Space → Remove → Browser → Helium
```

---

## Files Changed

| File | Change |
|------|--------|
| `omarchy-default-browser` | Added `helium` detection + set |
| `omarchy-install-browser` | Added Helium install from AUR |
| `omarchy-remove-browser` | Added Helium remove + Chromium fallback |
| `omarchy-menu` | Added Helium to Setup/Install/Remove menus |
| `omarchy-launch-webapp` | Added Firefox/Zen `--new-window`, `helium` `--app` support |

---

## Notes

- **Live in:** `~/.local/share/omarchy/bin/` — managed by Omarchy git. May be overwritten on `omarchy update`. Re-run `install.sh` after updates.
- **Backups created automatically** by `install.sh` with `.bak` suffix.
- **Default browser:** Omarchy ships with Chromium. Helium is an add-on you switch to anytime.

---

## Links

- [Helium Browser](https://heliumbrowser.com/)
- [AUR: helium-browser-bin](https://aur.archlinux.org/packages/helium-browser-bin)
- [Omarchy](https://omarchy.org/)
