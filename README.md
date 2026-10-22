# omarchy-browsers

Add **four extra browsers** to [Omarchy](https://omarchy.org) — with full menu
integration for Install, Remove, and Defaults:

| Browser | Package | Source | Command | Desktop entry |
|---|---|---|---|---|
| **Helium** | `helium-browser-bin` | omarchy repo | `helium-browser` | `helium.desktop` |
| **LibreWolf** | `librewolf` | official (`extra`) | `librewolf` | `librewolf.desktop` |
| **Waterfox** | `waterfox-bin` | AUR | `waterfox` | `waterfox.desktop` |
| **Vivaldi** | `vivaldi` + `vivaldi-ffmpeg-codecs` | official (`extra`) | `vivaldi` | `vivaldi-stable.desktop` |

Omarchy itself only ships chrome, brave, brave-origin, edge, firefox and zen.
This project extends the stock menu with the four above — no changes under
`/usr/share/omarchy` (everything lives in your home directory).

## Quick start

```bash
cd ~/Documents/omarchy-browsers

# 1. Add the menu rows (Install / Remove / Defaults for each browser)
./menu-setup.sh

# 2. Install just one browser, e.g. Helium only
./install-helium.sh

# 3. Make it the default
./set-default.sh helium
```

That's it — Super+X shows the new rows under **Install > Browser**,
**Remove > Browser** and **Setup > Defaults > Browser**.

## Scripts

### Install

| Script | What it does |
|---|---|
| `install-helium.sh` | Install Helium only |
| `install-librewolf.sh` | Install LibreWolf only |
| `install-waterfox.sh` | Install Waterfox only |
| `install-vivaldi.sh` | Install Vivaldi (with `vivaldi-ffmpeg-codecs`) |
| `install-all.sh` | Install all four |

Installs are idempotent — an already-installed browser is skipped. Official
packages go through `omarchy pkg add`, AUR packages through
`omarchy pkg aur add` (sudo will prompt in the terminal).

### Remove

| Script | What it does |
|---|---|
| `remove-helium.sh` … `remove-vivaldi.sh` | Remove that browser only |
| `remove-all.sh` | Remove every browser this project installed |

Removal is **complete and safe**:

- removes the package(s) via `omarchy pkg drop`
- if the removed browser was the **default**, the default is automatically
  handed over to the next installed browser (chromium → firefox → brave-origin
  → …) before xdg loses its handler
- `--purge` flag additionally deletes the browser's config, profile and cache
  directories (`~/.config/<browser>`, `~/.local/share/<browser>`, …) —
  without it, your profiles survive so you can reinstall later

```bash
./remove-waterfox.sh            # keep profile data
./remove-waterfox.sh --purge    # wipe profile data too
./remove-all.sh --purge
```

### Default browser

```bash
./set-default.sh                # status table: what's installed, what's default
./set-default.sh vivaldi        # make Vivaldi the default
./set-default.sh firefox        # works for Omarchy's stock browsers too
```

The stock `omarchy-default-browser` only knows the six built-in browsers;
`set-default.sh` extends the same `xdg-settings` + notification flow to the
new ones (with an `xdg-mime` fallback and verification).

### Menu integration

| Script | What it does |
|---|---|
| `menu-setup.sh` | (Re)generates the menu rows in `~/.config/omarchy/extensions/omarchy-menu.jsonc` |
| `menu-teardown.sh` | Removes the rows again (installed browsers are untouched) |

Both are idempotent. The rows live in a marked block, regenerated from
`lib/core.sh` on every `menu-setup.sh` run — **edit `lib/core.sh`, then re-run
`menu-setup.sh`** rather than editing the block by hand.

## How the menu integration works

Omarchy loads its menu from the read-only default
(`/usr/share/omarchy/default/omarchy/omarchy-menu.jsonc`) and merges your
user file (`~/.config/omarchy/extensions/omarchy-menu.jsonc`) into it — the
user file hot-reloads on save. `menu-setup.sh` writes three rows per browser:

- **Install › Browser** — `when: ! omarchy-pkg-present <pkg>` (hidden once installed),
  action launches the per-browser installer in Omarchy's floating terminal
- **Remove › Browser** — `when: omarchy-pkg-present <pkg>` (hidden once removed)
- **Setup › Defaults › Browser** — `when: omarchy-cmd-present <cmd>`,
  `checked:` runs `set-default.sh <name> --check` (draws the ✓), action runs
  `set-default.sh <name>`

### The Helium icon font

Menu rows render their `icon` as **text in a font** — images aren't supported,
but a row may override the font family with `iconFont`. Helium's official
logo is an 8-spike starburst that no Nerd Font glyph matches, so this project
ships a tiny one-glyph icon font built straight from Helium's official SVG
(<https://helium.computer/icon/helium-app-icon.svg>):

- `assets/build-helium-icon-font.py` — regenerates
  `assets/OmarchyHeliumIcon.ttf` (glyph `U+E00B`, a private-use codepoint the
  Nerd Font doesn't use, so a broken install shows a placeholder instead of a
  wrong icon). Needs `fontTools` (`pip install fonttools`).
- `menu-setup.sh` installs the `.ttf` into `~/.local/share/fonts/` and runs
  `fc-cache` (only when it changed), and the three Helium rows get
  `"iconFont": "OmarchyHeliumIcon"`.
- `menu-teardown.sh` removes the font again.

The registry's last two optional fields drive this: `menu glyph | icon font
family`. Other browsers leave them empty and render in the normal Nerd Font.

Glyph-metrics note (baked into the builder): the menu centres the icon *text*
— its advance box — inside a fixed-width cell. The builder therefore gives
the star an advance exactly equal to its ink width with the ink starting at
the origin, so the icon renders dead-centre in the cell. Don't "fix" spacing
with a zero advance: **Qt drops zero-advance glyphs and the icon disappears**.
The build is byte-reproducible (fixed `head` timestamp), which is what lets
`menu-setup.sh` use `cmp` to skip reinstalling an unchanged font.

If the Helium icon doesn't appear after `./menu-setup.sh`, Qt may have cached
the font list before the font was installed — run `omarchy-restart-shell`.

## Layout

```
omarchy-browsers/
├── README.md               ← this file
├── lib/
│   └── core.sh             ← the registry + install/remove/default logic
├── assets/                  ← Helium icon SVG + icon-font builder
├── install-helium.sh       ← per-browser installers (one browser each)
├── install-librewolf.sh
├── install-waterfox.sh
├── install-vivaldi.sh
├── install-all.sh          ← everything at once
├── remove-helium.sh        ← per-browser removals (--purge wipes profiles)
├── remove-librewolf.sh
├── remove-waterfox.sh
├── remove-vivaldi.sh
├── remove-all.sh
├── set-default.sh          ← default browser for new + stock browsers
├── menu-setup.sh           ← adds the menu rows
└── menu-teardown.sh        ← removes the menu rows
```

Everything is driven by the `BROWSER_REGISTRY` table in `lib/core.sh` —
add a browser there and re-run `./menu-setup.sh` to extend the whole system.

## Uninstall this project entirely

```bash
./remove-all.sh --purge    # remove every browser + profile data
./menu-teardown.sh         # remove the menu rows
rm -rf ~/Documents/omarchy-browsers
```

## Troubleshooting

- **Menu rows don't appear** — run `./menu-setup.sh` again and check the file
  parses (the script validates it automatically when `node` is available).
  Menus hot-reload, so reopening Super+X is enough.
- **AUR install fails** — make sure the AUR is reachable
  (`omarchy pkg aur accessible`) and `yay` works.
- **✓ doesn't move in Defaults** — run `./set-default.sh <name>` in a terminal
  to see the error; `./set-default.sh` (no args) shows what xdg currently
  reports as default.
- **Wrong icon / name in the menu** — everything cosmetic comes from
  `lib/core.sh`; edit and re-run `./menu-setup.sh`.
