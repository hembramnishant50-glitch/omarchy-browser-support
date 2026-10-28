# Installation manual

Everything you need to go from a bare Arch Linux + Omarchy machine to running
the browser you actually want, through this tool.

The short version:

```bash
git clone https://github.com/hembramnishant50-glitch/omarchy-browser-support.git
cd omarchy-browser-support
./install.sh
omarchy-browsers install <your-browser>
omarchy-browsers default <your-browser>
```

The rest of this document walks through each step in detail, one browser at a
time.

---

## 0. Prerequisites

| Requirement | Version / note |
|---|---|
| [Omarchy](https://omarchy.org) | 4.x (Arch Linux). The tool reports `Omarchy 4.0.6-1` at time of writing. |
| Bash | 4.3 or newer (5.x on current Arch). |
| Arch Linux packages | `pacman` and, for AUR browsers, the package manager Omarchy uses (it installs `yay` on demand). |
| Network | needed for first install (Omarchy repos / AUR). |

No other dependencies. The tool is Bash only, and it degrades gracefully when
optional tools are absent.

---

## 1. Install the tool

```bash
git clone https://github.com/hembramnishant50-glitch/omarchy-browser-support.git
cd omarchy-browser-support
./install.sh
```

What `install.sh` does:

1. Creates a symlink in `$XDG_BIN_HOME` (default `~/.local/bin`) pointing at
   `bin/omarchy-browsers` — **no files are copied**, so a later `git pull`
   updates the tool in place.
2. Runs `menu setup`, which installs the bundled Helium icon font
   (`OmarchyHeliumIcon`) and writes the managed block into
   `~/.config/omarchy/extensions/omarchy-menu.jsonc`.

Options:

| Option | Effect |
|---|---|
| `--no-menu` | only create the symlink; run `omarchy-browsers menu setup` yourself later |
| `--bin-dir DIR` | link into a directory of your choice instead of `~/.local/bin` |
| `--dry-run` | print every action, change nothing |

After the first `menu setup`, restart the Omarchy shell once (or log out and
back in) so Qt loads the new font. Only the menu glyph waits on that; the menu
rows appear immediately.

---

## 2. Choose a browser

| Browser | Registry id | Packages | Source | CLI command | Desktop id | Profile paths |
|---|---|---|---|---|---|---|
| **Helium** | `helium` | `helium-browser-bin` | official repo | `helium-browser` | `helium.desktop` | `~/.config/helium …` |
| **LibreWolf** | `librewolf` | `librewolf` | official repo | `librewolf` | `librewolf.desktop` | `~/.librewolf` |
| **Waterfox** | `waterfox` | `waterfox-bin` | AUR | `waterfox` | `waterfox.desktop` | `~/.waterfox` |
| **Vivaldi** | `vivaldi` | `vivaldi`, `vivaldi-ffmpeg-codecs` | official repo | `vivaldi` | `vivaldi-stable.desktop` | `~/.config/vivaldi` |
| **Floorp** | `floorp` | `floorp-bin` | AUR | `floorp` | `floorp.desktop` | `~/.floorp`, `~/.config/floorp`, `~/.cache/floorp` |

Omarchy's stock browsers (Chromium, Chrome, Brave, Brave Origin, Edge, Firefox,
Zen) can also be set as the default through the same default-browser mechanism;
nothing here replaces them.

---

## 3. Install the browser you want

### Helium (the flagship)

```bash
omarchy-browsers install helium
omarchy-browsers default helium
```

Helium is the only browser in the registry with its **real starburst** in the
menu, rendered through the bundled `OmarchyHeliumIcon` font (glyph `U+E00B`) and
installed automatically by `menu setup`. If the row shows a box or tofu, follow
[docs/helium-icon.md](helium-icon.md).

### LibreWolf

```bash
omarchy-browsers install librewolf
omarchy-browsers default librewolf
```

### Waterfox

```bash
omarchy-browsers install waterfox
omarchy-browsers default waterfox
```

Waterfox comes from the AUR, so the install runs through Omarchy's AUR flow
(`omarchy pkg aur add waterfox-bin`).

### Vivaldi

```bash
omarchy-browsers install vivaldi
omarchy-browsers default vivaldi
```

Vivaldi installs **two** packages together — the browser and the ffmpeg codecs —
because the registry lists them as one install. The Install menu row hides only
when the *primary* package (`vivaldi`) is present; the codecs finish the setup
through the row if they are missing.

### Floorp

```bash
omarchy-browsers install floorp
omarchy-browsers default floorp
```

Floorp is AUR-hosted; `omarchy-browsers install floorp` routes through the AUR
flow as well.

### All of them

```bash
omarchy-browsers install all
```

Installs every browser in the registry.

---

## 4. Verify

```bash
omarchy-browsers status        # installed? default? who owns http(s)?
omarchy-browsers doctor         # full diagnostics
omarchy-browsers menu status   # managed block + validation
```

Then open **Super+X › Setup › Defaults › Browser** (or the browser submenu in
the Install / Remove sections) and check that:

- the Install row is gone for an installed browser;
- the Remove row is present for it;
- the Setup › Defaults › Browser row shows the ✓ on your default.

---

## 5. Switching browsers later

Nothing is special about install order — you can install, default and remove in
any order, and switching is just:

```bash
omarchy-browsers default <name>   # e.g. librewolf
```

The default row embeds a check command, so the ✓ updates after the switch.
`status` tells you which browser currently owns your `http(s)` associations.

---

## 6. Remove a browser

```bash
omarchy-browsers remove <name>          # uninstall, keep profiles
omarchy-browsers remove <name> --purge # uninstall + wipe profile paths
omarchy-browsers remove all --purge    # full uninstall of the registry
```

Removing never leaves you without a default: the tool hands the default role to
an installed survivor first.

---

## 7. Uninstall the tool itself

```bash
./uninstall.sh                 # remove menu block + the CLI symlink
./uninstall.sh --keep-menu     # keep the menu integration, drop the CLI
```

Or from anywhere, via the CLI:

```bash
omarchy-browsers remove all --purge
```

---

## 8. Troubleshooting the install itself

| Symptom | Fix |
|---|---|
| `omarchy-browsers: command not found` | `~/.local/bin` is not on your `PATH`, or you used `--bin-dir`. Add the dir, or relink. |
| Install fails on an AUR browser | `omarchy pkg aur accessible`, or install the package manually and run `omarchy-browsers menu setup`. |
| Browser installed but has no desktop entry | log out and back in (reindex), and check `pacman -Fl <package> \| grep .desktop`. |
| Menu shows nothing after install | `omarchy-browsers menu setup`, then check `Super+X › …` scope. |
| Everything looks wrong | `omarchy-browsers doctor`. |

Full symptom list: [docs/troubleshooting.md](troubleshooting.md).

---

## Manuals for specific browsers (long form)

- **Switching to LibreWolf / Waterfox / Vivaldi / Floorp / a stock browser** — see
  the [Commands reference in the README](../README.md#commands).
- **Adding your own browser to the registry** — [docs/adding-a-browser.md](adding-a-browser.md).
- **Why Helium has a font instead of a Nerd Font glyph** — [docs/helium-icon.md](helium-icon.md).
- **How the whole thing works** — [docs/architecture.md](architecture.md).
