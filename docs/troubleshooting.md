# Troubleshooting

Start here:

```bash
omarchy-browsers doctor
```

It checks your Bash version, the Omarchy tree, the registry, the menu file, the
icon font, the default browser, every installed browser and AUR reachability.
Each line is `ok`, `warn` or `fail`; warnings are survivable, failures exit
non-zero. Most problems below have a `doctor` line that names them.

---

## The menu

### The Browser submenus are empty or missing

The managed block is not in the menu file.

```bash
omarchy-browsers menu setup
omarchy-browsers menu status
```

`menu status` prints the file path, the row count and the validation result. If
setup says it wrote rows but the menu still looks empty, the shell is reading a
different config:

```bash
echo "$XDG_CONFIG_HOME"        # if set, the menu lives below it
ls -l "${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/extensions/omarchy-menu.jsonc"
```

### Helium shows a box, a blank cell, or a generic globe

Three different causes, in order of likelihood:

1. **The icon font is not installed.** `menu setup` installs
   `$XDG_DATA_HOME/fonts/OmarchyHeliumIcon.ttf`.

   ```bash
   ls -l "${XDG_DATA_HOME:-$HOME/.local/share}/fonts/OmarchyHeliumIcon.ttf"
   fc-list | grep -i OmarchyHeliumIcon
   ```

2. **The shell started before the font existed.** Qt builds its font database at
   startup, so a running shell cannot see a family installed afterwards.
   Restart it once:

   ```bash
   omarchy-restart-shell
   ```

   This is safe — it restarts the bar and menu, not your session. Logging out
   and back in has the same effect.

3. **The font file is stale or truncated.** Rerun setup; it compares bytes and
   reinstalls when they differ.

   ```bash
   omarchy-browsers menu setup
   ```

If the cell is blank rather than a box, the font is present but the glyph is
gone — a `menu setup` rewrites both the font and the rows together.

### The rows point at an old path

Menu actions embed the **absolute path** to `bin/omarchy-browsers`. Moving or
renaming the checkout breaks every row.

```bash
omarchy-browsers menu setup     # rewrite with the current path
```

`install.sh` deliberately creates a symlink instead of copying, so `git pull`
updates the tool in place — it cannot fix embedded paths, only `menu setup` can.

### My own menu edits disappeared

Only text between the two markers is replaced:

```text
// >>> omarchy-browser-support
// <<< omarchy-browser-support
```

Anything outside them — including rows you added by hand, comments and
formatting — is preserved. If you edited *inside* the markers, re-add it
outside: the block is generated from `lib/browsers.tsv` on every run.

### The default column has no ✓

The ✓ comes from `omarchy-cmd-default-browser`. Check it directly:

```bash
omarchy-cmd-default-browser
omarchy-browsers default
omarchy-browsers default helium   # or whichever you want
```

A ✓ requires the browser's command to be on `PATH` (`omarchy-cmd-present`), so a
freshly installed browser may need a new shell before its row appears in
`Setup › Defaults › Browser`.

### "menu validation failed"

Setup refused to write because the merged result did not match what the registry
expects — a missing row, a row that lost its `icon`, or one that lost its
`iconFont`. The live file was left untouched.

```bash
node --version                        # validation needs node
ls /usr/share/omarchy/shell/plugins/menu/MenuModel.js
```

If `node` is missing, validation is skipped with a warning instead. If the file
itself is hand-edited into invalid JSONC, setup reports the parse error; repair
the file (or delete it — setup recreates a minimal one) and rerun.

---

## Browsers

### `install` fails on an AUR browser

Waterfox and Floorp are AUR packages. The tool calls `omarchy pkg aur add`,
which needs `yay` and a working network path to the AUR.

```bash
omarchy pkg aur accessible
omarchy-browsers --dry-run install waterfox    # see the exact command
```

If the AUR is unreachable, `doctor` says so in its *Repositories* section.
Retry later or install the package yourself and rerun `menu setup`.

### "installed but no .desktop entry found"

`doctor` fails here because the browser cannot appear in `Setup › Defaults ›
Browser` without a desktop entry.

- Log out and back in so the desktop database is reindexed.
- Confirm the package actually ships one:

  ```bash
  pacman -Fl <package> | grep '\.desktop'
  ```

  If the id differs from the registry, update column 6 — see
  [adding-a-browser.md](adding-a-browser.md).

### A browser is installed but its Install row is still there

Menu visibility asks about the **primary** package only. If a companion package
(codecs, language pack) is missing, the row stays so you can finish the install.

```bash
omarchy-browsers status | grep -i vivaldi
pacman -Q vivaldi vivaldi-ffmpeg-codecs
```

### `remove` refuses to run

Removal hands the default-browser role to a survivor first. If nothing else is
installed and no stock browser is present, there is nothing to hand it to — the
command stops instead of leaving `http(s)` unowned. Install another browser, or
set a stock one as default, then remove.

### `--purge` left something behind

`--purge` removes exactly the paths in the registry's tenth column, and only
paths under `$HOME`. Files the browser wrote elsewhere — downloads, exports,
`/tmp` scratch — are not touched on purpose. Compare what remains with the row:

```bash
omarchy-browsers list
ls -d ~/.config/<name> ~/.cache/<name> 2>/dev/null
```

### A removal uninstalled more than expected

Vivaldi's row declares two packages; both are removed together because they are
one install. If you want to keep the codec pack, remove the browser with
`pacman -R` directly and rerun `menu setup`.

---

## The CLI itself

### `omarchy-browsers: command not found`

The symlink lives in `$XDG_BIN_HOME` or `~/.local/bin`.

```bash
ls -l ~/.local/bin/omarchy-browsers
echo "$PATH" | tr ':' '\n' | grep -F "$HOME/.local/bin"
```

Add the directory to your shell profile, or rerun `./install.sh --bin-dir DIR`
with a directory that is already on `PATH`.

### The symlink is broken after moving the checkout

```bash
./uninstall.sh          # removes the link only if it points here
./install.sh            # relink from the new location
omarchy-browsers menu setup
```

`uninstall.sh` will not delete a link that points somewhere else — that guard is
intentional.

### Wrong colours or escape codes in logs

```bash
omarchy-browsers --no-color status
NO_COLOR=1 omarchy-browsers status
```

`--no-color` and the `NO_COLOR` convention are both honoured, including when
piped.

### Bash version errors

Bash 4.3 or newer is required (associative arrays and `wait -n` behaviour). Arch
ships 5.x; a failure here usually means a script was run with `sh` instead of
`bash`.

```bash
bash --version | head -1
```

---

## Tests

If you are developing, not using, the tool:

```bash
tests/run.sh --list
tests/run.sh menu --verbose
```

Suites are hermetic: they build a temporary `HOME`, stub `omarchy`, `pacman`,
`xdg-settings` and `fc-cache`, and point `OMARCHY_PATH` at
`tests/fixtures/omarchy`. A failure there is reproducible without touching your
real configuration. Two common causes:

- **`node` missing** — menu validation is skipped and the validation assertions
  are looser; install `nodejs` for the full run.
- **A stale fixture** — `tests/fixtures/omarchy/` must contain the default menu
  and `MenuModel.js`; it is committed, so `git status` should be clean.

---

## Reporting a problem

Include the output of:

```bash
omarchy-browsers version
omarchy-browsers doctor
omarchy-browsers menu status
```

…and, if the menu is involved, the block from your menu file between the two
markers. Open an issue at
<https://github.com/hembramnishant50-glitch/omarchy-browser-support/issues>.
