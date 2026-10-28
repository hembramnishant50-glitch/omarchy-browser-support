# Architecture

This document describes how `omarchy-browser-support` is put together: the file
layout, the registry contract, what happens on each command, and the invariants
that keep it safe to run on a machine you care about.

The whole project is Bash — no build step, no runtime dependencies beyond what
Omarchy already provides.

---

## Layout

```text
bin/omarchy-browsers      dispatcher: argument parsing, help, exit codes
lib/browsers.tsv          the registry — one row per browser, 10 TSV columns
lib/core.sh               registry loader + install / remove / default / status
lib/menu.sh               the Omarchy menu block, icon fonts, validation
lib/doctor.sh             diagnostics, ok / warn / fail
assets/                   Helium app icon, the one-glyph font, its build script
assets/readme/            banner SVGs and the real menu screenshot
tests/                    hermetic suites plus a fake Omarchy tree
docs/                     this file and the task-oriented guides
install.sh                link the CLI, then run `menu setup`
uninstall.sh              remove the link (only if it points at this checkout)
```

Three rules shaped the layout:

1. **One entry point.** Everything users type goes through
   `bin/omarchy-browsers`. The libraries are sourced, never executed.
2. **Data, not code.** Browsers live in `lib/browsers.tsv`. Adding one is a
   line, not a new script — the pre-1.0 tree had thirteen near-identical
   `install-*.sh` / `remove-*.sh` files that all drifted apart.
3. **Nothing outside `$HOME` is written.** `/usr/share/omarchy` is read-only
   input: the default menu definition and `MenuModel.js` are used to validate
   what we generate.

---

## The registry

`lib/browsers.tsv` is tab-separated, one browser per line, `#` starts a comment.
Columns, in order:

| # | Column | Meaning |
|---|---|---|
| 1 | `name` | CLI id and menu-row suffix: lowercase letters, digits, dashes |
| 2 | `display` | Human name shown in the menu and output |
| 3 | `packages` | Comma-separated Arch packages; **the first is primary** |
| 4 | `source` | `repo` (official / Omarchy repos) or `aur` |
| 5 | `command` | Executable the package provides |
| 6 | `desktops` | Comma-separated `.desktop` ids; the first is preferred |
| 7 | `glyph` | Nerd Font glyph for notifications, `U+XXXX` or a literal char |
| 8 | `menu_glyph` | Optional menu-only glyph; empty means "use `glyph`" |
| 9 | `icon_font` | Optional Qt font family shipped in `assets/<family>.ttf` |
| 10 | `purge` | Space-separated paths under `$HOME` wiped by `remove --purge` |

Current contents:

```text
helium     Helium     helium-browser-bin   repo  helium-browser   helium.desktop
librewolf  LibreWolf  librewolf            repo  librewolf        librewolf.desktop
waterfox   Waterfox   waterfox-bin         aur   waterfox         waterfox.desktop
vivaldi    Vivaldi    vivaldi,vivaldi-ffmpeg-codecs repo vivaldi  vivaldi-stable.desktop
floorp     Floorp     floorp-bin           aur   floorp           floorp.desktop
```

### Why the primary package matters

`omarchy-pkg-present <pkg>` succeeds only when **all** packages in the list are
installed, while `omarchy-pkg-missing <pkg>` succeeds when **any** one is
missing. The generated menu asks about the *primary* package for visibility, so
Vivaldi's two-package install (browser + ffmpeg codecs) still shows up correctly,
and `install` installs both in one transaction.

### Loading and validation

`load_registry` runs once, from `lib/core.sh`, and fills associative arrays
(`BROWSER_DISPLAY`, `BROWSER_PACKAGES`, `BROWSER_SOURCE`, `BROWSER_COMMAND`,
`BROWSER_DESKTOPS`, `BROWSER_GLYPH`, `BROWSER_MENU_GLYPH`, `BROWSER_ICON_FONT`,
`BROWSER_PURGE`) plus the ordered `BROWSER_NAMES` array.

It fails loudly (exit 1, with the line number) on:

- a malformed name, or an empty display / packages / command / desktops field;
- a `source` other than `repo` or `aur`;
- a duplicate `name`;
- an absolute purge path or one containing `..` — purge targets must stay inside
  `$HOME`.

Fields are split by a hand-written `split_tsv`, not `IFS=$'\t' read -a`, because
the latter collapses empty fields and the optional columns (`menu_glyph`,
`icon_font`) are empty for four of the five browsers.

Glyph columns accept `U+XXXX` (decoded to real UTF-8 bytes at load time, so the
file stays ASCII and editable) or a literal character.

---

## Command flow

`bin/omarchy-browsers` resolves its own path through any chain of symlinks
(`resolve_self`), sets `OMARCHY_BROWSERS_ROOT`, sources the three libraries, then
dispatches. `--dry-run` and `--no-color` are accepted before or after the
subcommand.

| Command | Path through the code |
|---|---|
| `install <name…>` | `install_browser` → `omarchy pkg add` / `omarchy pkg aur add` → `detect_desktop` → hint |
| `remove <name…>` | `remove_browser` → `pick_fallback_default` → uninstall → optional `purge_browser_paths` |
| `default [<name>]` | `check_default` (with `--check`) or `set_default_browser` via `xdg-settings` |
| `status [--json]` | `print_status` / `print_status_json`, both built on `detect_desktop` |
| `list` | `print_browser_table` straight from the registry |
| `menu setup` | `menu_install_fonts` → `menu_block` → `insert_block` → `validate_menu` → `menu_write` |
| `menu teardown` | `strip_managed_blocks` → `menu_write` → `menu_remove_fonts` |
| `menu status` | presence of the marker + `validate_menu` |
| `doctor` | `lib/doctor.sh` checks, aggregated into an exit code |

Every mutating step goes through `run_cmd`, which prints and skips when
`DRY_RUN=1`. That is the only reason `--dry-run` can be trusted to change
nothing.

### Default-browser handling

Omarchy delegates the default browser to `xdg-settings`. We read it with
`current_default_desktop`, which returns the `.desktop` id currently owning
`http(s)`; `detect_desktop` maps a registry browser to that id by trying the
declared ids first and then matching each candidate's `Exec=` against the
browser's command. This is why `status` shows the real owner even when a user
picked a stock browser.

`remove` refuses to leave the system without a default: `pick_fallback_default`
chooses an installed, runnable survivor (the stock browsers are candidates too)
and hands the role over before the package disappears.

---

## Menu integration

Omarchy merges `~/.config/omarchy/extensions/omarchy-menu.jsonc` over its own
definition. `lib/menu.sh` owns exactly one marked block in that file:

```text
// >>> omarchy-browser-support
...15 generated rows...
// <<< omarchy-browser-support
```

`menu setup` is intentionally boring:

1. **Prepare** the file — create `{}`, normalise an empty or compact file.
2. **Install icon fonts** — copy `assets/<family>.ttf` into
   `$XDG_DATA_HOME/fonts` when it is missing or differs, then `fc-cache -f`
   once.
3. **Prune** fonts that earlier versions installed and the registry no longer
   asks for (`LEGACY_ICON_FONTS`, currently empty).
4. **Generate** the block from the registry.
5. **Insert** it before the final `}`, adding the trailing comma the previous
   key needs.
6. **Validate** the merged result with Omarchy's own `MenuModel.js` through
   `node`: every expected row must exist, keep its `icon`, and keep its
   `iconFont` when the registry declares one.
7. **Write atomically** — `mktemp` in the same directory, `mv` over the target,
   skipped entirely when the content is byte-identical.

If step 6 fails, the live file is never replaced. If `node` or `MenuModel.js` is
missing, validation is skipped with a warning rather than blocking the user.

`menu teardown` runs the same pipeline with the block stripped: user rows,
comments and formatting outside the markers survive, and only the fonts the
registry owns are removed.

`menu status` and `doctor` report the marker, the row count, the font families
and the validation result.

### Rows and routing

For each browser, three rows are generated:

| Row id | Route | Visibility |
|---|---|---|
| `install.browser.<name>` | `Install › Browser` | `! omarchy-pkg-present <primary>` |
| `remove.browser.<name>` | `Remove › Browser` | `omarchy-pkg-present <primary>` |
| `setup.default.browser.<name>` | `Setup › Defaults › Browser` | `omarchy-cmd-present <command>` |

The default row carries `checked: "<cli> default <name> --check"`, so Omarchy
draws the ✓ on the current browser. Actions are wrapped in
`omarchy-launch-floating-terminal-with-presentation` so installs and removals
run in a visible terminal.

Rows embed the **absolute path** to `bin/omarchy-browsers`. Moving the checkout
therefore requires `menu setup` again — that is the one piece of state a symlink
cannot hide.

---

## Invariants

These are enforced by code and by tests; a change that breaks one is a bug.

1. `/usr/share/omarchy` is never written to.
2. The only files touched are the menu JSONC (inside the markers), the font
   files named by the registry, and the symlink created by `install.sh`.
3. `--dry-run` performs no writes, no `fc-cache`, no package operations.
4. Menu writes are atomic and idempotent.
5. An invalid merge never replaces a valid menu file.
6. Purge paths are relative to `$HOME`, contain no `..`, and are removed only
   with `--purge`.
7. `uninstall.sh` deletes the link only when it resolves to this checkout.
8. Removing a browser never leaves the system with no default browser.
9. Every glyph the registry declares has a source: Nerd Font, or a font file in
   `assets/` that `menu setup` installs.

---

## Tests

`tests/` is hermetic by construction: `tests/helpers/env.sh` creates a
throwaway `HOME`, `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_DATA_DIRS` and a
`bin/` full of stubs for `omarchy`, `pacman`, `xdg-settings`, `fc-cache` and
friends. `OMARCHY_PATH` points at `tests/fixtures/omarchy`, a miniature copy of
the real tree with the default menu and `MenuModel.js`.

```bash
tests/run.sh                 # everything
tests/run.sh menu --verbose  # one suite
tests/run.sh --list
```

The suites cover the CLI surface, registry validation, install/remove/default,
desktop detection, menu generation and teardown, the installer scripts, doctor
and the JSON schema. See [CONTRIBUTING.md](../CONTRIBUTING.md) for the
assertion helpers and how to add a case.
