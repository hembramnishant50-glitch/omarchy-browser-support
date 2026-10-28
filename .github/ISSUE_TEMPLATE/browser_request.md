---
name: Browser request
about: Ask for a browser that is not in the registry yet
title: "browser: "
labels: enhancement
assignees: ""
---

## Browser

- **Name:**
- **Website:**
- **Package** (repo or AUR):
- **Executable:**
- **Desktop id** (`ls /usr/share/applications | grep -i <name>`):

## Why this one

<!-- What does it do that Helium, LibreWolf, Waterfox, Vivaldi or Floorp do not? -->

## Profile paths

Where does it keep its data? Run it once and check:

```bash
ls -d ~/.config/<name> ~/.cache/<name> ~/.local/share/<name> ~/.<name> 2>/dev/null
```

## Checks

- [ ] the package installs cleanly on Arch today
- [ ] the executable name matches the desktop entry's `Exec=`
- [ ] I have read [docs/adding-a-browser.md](../../docs/adding-a-browser.md)

## Icon

Menu rows render text, so a real logo needs a bundled icon font. Would a Nerd
Font glyph be acceptable, or is the official mark essential here?
