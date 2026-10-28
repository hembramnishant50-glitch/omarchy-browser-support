# Adding a browser

Adding a browser is one line in `lib/browsers.tsv` plus a `menu setup`. The
installer, remover, menu rows, status output, `doctor` and the docs table all
read from that row.

This guide walks through a complete example — **Ulaa**, a Chromium-based
browser available from the AUR — then lists the checks to run.

---

## 1. Find the facts

You need five things before you touch the registry:

| What | Where to look |
|---|---|
| Package name | `pacman -Ss ulaa` or the AUR page |
| Repo or AUR | `pacman -Si ulaa` (fails → AUR) |
| Executable | `pacman -Fl <pkg> | grep bin/` or the `.desktop` file |
| `.desktop` id | `pacman -Fl <pkg> | grep '\.desktop'` |
| Profile paths | run it once, then look under `~/.config`, `~/.local/share`, `~/.cache` |

Verify the command against the desktop entry rather than guessing:

```bash
grep '^Exec=' /usr/share/applications/ulaa.desktop
```

The first token of `Exec=` is what column 5 must contain. If the package ships
several desktop ids (common for Chromium forks), list them all in column 6 —
`detect_desktop` tries them in order and then falls back to matching `Exec=`.

---

## 2. Add the row

Columns are tab-separated, in this order:

```text
name  display  packages  source  command  desktops  glyph  menu_glyph  icon_font  purge
```

```tsv
ulaa	Ulaa	ulaa-bin	aur	ulaa	ulaa.desktop	U+F269		.config/ulaa .cache/ulaa
```

Notes:

- **`name`** — lowercase letters, digits and dashes. This becomes the CLI id and
  the menu row suffix, so it must be stable.
- **`packages`** — comma-separated. The **first** is primary: it drives menu
  visibility and the "is it installed?" check. List companions (codec packs,
  language packs) after it and they install together.
- **`source`** — exactly `repo` or `aur`.
- **`glyph`** — `U+XXXX` from a [Nerd Font cheat
  sheet](https://www.nerdfonts.com/cheat-sheet), or a literal character. Prefer
  the `U+XXXX` form: the registry stays ASCII and the decoder handles it.
- **`menu_glyph`** — leave empty to reuse `glyph`. Fill it only when the menu
  needs a different mark than notifications.
- **`icon_font`** — leave empty unless you ship a font in `assets/`. See
  [helium-icon.md](helium-icon.md); four of the five current browsers reuse
  Nerd Font glyphs precisely to avoid this.
- **`purge`** — space-separated, relative to `$HOME`, no `..`, no absolute
  paths. The loader rejects anything else. Keep this list to data directories;
  never include `$HOME` itself or a shared cache.

Append the row anywhere — order is presentation order in `list`, `status`,
`doctor` and the menu. Put flagship or commonly used browsers first.

---

## 3. Regenerate and verify

```bash
omarchy-browsers list            # the row loads and prints correctly
omarchy-browsers menu setup      # regenerate the 3 new menu rows
omarchy-browsers menu status     # should report 18 rows and a clean validation
omarchy-browsers doctor          # no new warnings
```

`menu setup` prints the validation result. If it fails, the live menu file is
left untouched and you get the reason — a missing row, a lost `icon`, or a lost
`iconFont`.

---

## 4. Rehearse the operations

```bash
omarchy-browsers --dry-run install ulaa
omarchy-browsers --dry-run remove ulaa --purge
omarchy-browsers --dry-run default ulaa
```

Dry runs print every command they would execute and touch nothing. Check that:

- the package command is `omarchy pkg aur add ulaa-bin` (AUR) or
  `omarchy pkg add …` (repo);
- the purge paths are the ones you meant, and all under `$HOME`;
- the default switch targets the right desktop id.

Then do it for real, in this order, and confirm the menu after each step:

```bash
omarchy-browsers install ulaa
omarchy-browsers default ulaa
omarchy-browsers status
omarchy-browsers remove ulaa --purge
```

---

## 5. Update the tests

Two suites pin the registry so a row cannot be added or broken silently:

| File | What to update |
|---|---|
| `tests/test_registry.sh` | the browser list in *"loads every managed browser"* |
| `tests/test_doctor.sh` | the count in *"doctor reports the registry contents"* |

If the new row is the flagship, also update *"helium is the flagship row"* —
but normally you are appending, so Helium stays first.

Menu row counts appear in `tests/test_menu.sh` (`15` → `18`). Search for the
number rather than assuming:

```bash
grep -rn '"15"\|15 menu rows\|15 browser rows' tests/ lib/
```

Run the suite:

```bash
tests/run.sh
```

---

## 6. Update the README

The browser table in `README.md` is hand-written (it is prose, not generated).
Add the row in registry order, including its `--purge` paths. If the browser has
an icon in `assets/`, add a small `<img>` like Helium's; otherwise leave the
cell empty, as the other four do.

---

## Checklist

- [ ] package, source, executable and desktop id verified from the package itself
- [ ] row appended with all 10 columns, tabs not spaces
- [ ] purge paths relative, free of `..`, data-only
- [ ] `omarchy-browsers list` shows the row
- [ ] `menu setup` validates and reports `3 × browsers` rows
- [ ] `--dry-run` install / remove / default look right
- [ ] a real install, default switch, status and `--purge` removal work
- [ ] tests updated and `tests/run.sh` is green
- [ ] README table updated
- [ ] `CHANGELOG.md` has an entry under *Unreleased*

## A note on icon fonts

Tempting as it is to give every browser its real logo, each `icon_font` means
another TTF in `assets/`, another file in `$XDG_DATA_HOME/fonts`, and another
reason the menu shows tofu when the font cache is stale. Helium earns that
because it is the flagship and Omarchy has no row for it at all. For everything
else, a Nerd Font glyph that reads clearly at 16 px is the better trade.
