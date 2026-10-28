# The Helium icon

Helium is the flagship browser here, and its menu rows show the real starburst
from the official app icon. This document explains why that needed a font, how
the font is built, and what to do when the glyph does not appear.

---

## Why a font at all

An Omarchy menu row is a JSON object:

```jsonc
"install.browser.helium": {"icon": "", "iconFont": "OmarchyHeliumIcon", …}
```

The `icon` field is rendered as **text in the row's font**. There is no image
path, no SVG, no per-row pixmap — so shrinking `helium-app-icon.svg` into the
menu is not an option.

What a row *can* do is override the font family with `iconFont`. That turns the
problem into typography: put the starburst outline into a TrueType font at a
codepoint nothing else uses, and the menu renders it like any other glyph.

Two consequences worth knowing:

- The codepoint is **U+E00B**, in the Basic Multilingual Plane private-use area.
  Nerd Fonts do not map anything there, so a missing font shows tofu (an obvious
  error) rather than the wrong icon (a silent one).
- Because it is a font, it must be installed and cached before Qt can draw it —
  see [the restart](#the-restart) below.

Every other browser in the registry keeps a Nerd Font glyph. Helium is the one
case where the real mark is worth an extra file: Omarchy ships
`helium-browser-bin` but has no menu row for it, and a generic globe would make
it indistinguishable from LibreWolf.

---

## The files

| File | Role |
|---|---|
| `assets/helium-app-icon.svg` | the official icon, the source of truth for the outline |
| `assets/build-helium-icon-font.py` | rebuilds the TTF from the SVG, byte-reproducibly |
| `assets/OmarchyHeliumIcon.ttf` | the shipped font — one glyph, family `OmarchyHeliumIcon` |

The font is installed to
`${XDG_DATA_HOME:-$HOME/.local/share}/fonts/OmarchyHeliumIcon.ttf` by
`omarchy-browsers menu setup`, refreshed with `fc-cache -f`, and removed by
`omarchy-browsers menu teardown`.

---

## Building it

```bash
python3 -m pip install --user fonttools
python3 assets/build-helium-icon-font.py
```

The script:

1. parses the `d="…"` path from the SVG (straight `M`/`L` segments — the
   starburst is a single closed polygon);
2. scales it to **726 units** of a **1000 UPM** em square, about 73%, matching
   the optical size of the Nerd Font icons beside it;
3. centres it on the text line box — ascender 800, descender −200, centre 300
   units above the baseline;
4. sets the advance width to **exactly the ink width**, so the menu's fixed-width
   cell centres the star without padding;
5. writes a minimal TTF with `fontTools.fontBuilder`.

### The advance-width trap

This is the detail that cost the most time, so it is worth stating plainly.

The menu centres the icon's **advance box**, not its ink. Three naive choices
all fail:

| Advance | Result |
|---|---|
| `0` | Qt drops zero-advance glyphs entirely — the cell renders blank |
| full em (1000) with centred ink | the star sits half an em left, hugging the row edge |
| ink width, ink starting at 0 | ink and advance box coincide → dead centre ✅ |

The shipped font uses the third. If you ever change the placement, re-check it
in a real menu, not in a font preview — the preview centres ink, the menu centres
advance.

---

## The restart

Qt builds its font database when the process starts. A shell that was already
running when `menu setup` installed the font **cannot** see the new family, no
matter how many times the menu reopens.

```bash
omarchy-restart-shell
```

This restarts the Omarchy shell (bar and menu), not your session; logging out and
back in does the same thing more slowly. `menu setup` prints this hint the first
time it installs a font, and `doctor` reports `icon font installed:
OmarchyHeliumIcon` once the file is on disk.

The menu *rows* do not need the restart — they appear immediately. Only the
starburst waits for the font cache.

---

## When it does not render

Work through these in order; each has a matching `doctor` line.

```bash
omarchy-browsers doctor
```

1. **Font file missing** — `icon font missing: OmarchyHeliumIcon`. Run
   `omarchy-browsers menu setup`.

   ```bash
   ls -l "${XDG_DATA_HOME:-$HOME/.local/share}/fonts/OmarchyHeliumIcon.ttf"
   ```

2. **Font not registered with fontconfig** —

   ```bash
   fc-list | grep -i OmarchyHeliumIcon
   ```

   Empty output means the cache is stale: `fc-cache -f "$XDG_DATA_HOME/fonts"`.
   `menu setup` does this for you unless `fc-cache` is unavailable.

3. **Shell predates the font** — restart it (above). This is the most common
   cause and the least obvious.

4. **Rows lost their `iconFont`** — `menu validation failed — rows lost their
   iconFont`. Something edited the block by hand; `menu setup` regenerates it.

5. **A box instead of a star** — the font is installed but the family name does
   not match. Check the registry's ninth column against the font's family:

   ```bash
   fc-scan --format '%{family}\n' assets/OmarchyHeliumIcon.ttf
   ```

   It must read `OmarchyHeliumIcon`.

If the cell is **blank** rather than a box, suspect a zero advance — a modified
or rebuilt font. Rebuild from the shipped SVG and compare bytes:

```bash
python3 assets/build-helium-icon-font.py
git status --short assets/OmarchyHeliumIcon.ttf   # should be clean
```

---

## License

`assets/helium-app-icon.svg` is Helium's official app icon, fetched from
<https://helium.computer>. It is used here to render the menu glyph and the
README art; all rights remain with the Helium project. See the note in
[Credits](../README.md#credits) and the repository's
[LICENSE](../LICENSE).
