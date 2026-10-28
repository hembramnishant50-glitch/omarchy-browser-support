# Contributing

Thanks for taking a look. This is a small Bash project with a deliberate shape:
one dispatcher, one registry, and tests that never touch your real system. This
guide covers the loop, the style, and what a pull request needs.

---

## Getting set up

```bash
git clone https://github.com/hembramnishant50-glitch/omarchy-browser-support.git
cd omarchy-browser-support

./install.sh --no-menu     # link the CLI, leave your menu alone
tests/run.sh               # 9 suites, 155 checks, ~15 s
```

You do **not** need Omarchy installed to run the tests. You do need Bash 4.3+.

Optional tools, all of which `make check` uses when present:

| Tool | What it adds |
|---|---|
| `shellcheck` | static analysis (CI runs it) |
| `node` | full menu validation with Omarchy's real `MenuModel.js` |
| `python3` + `fonttools` | only if you rebuild the icon font |

On Arch:

```bash
sudo pacman -S shellcheck nodejs
```

---

## The loop

```bash
tests/run.sh                     # everything
tests/run.sh menu --verbose      # one suite, streamed output
tests/run.sh --list              # what exists
make check                       # bash -n + shellcheck + tests
```

Each suite creates a throwaway `HOME`, `XDG_CONFIG_HOME`, `XDG_DATA_HOME` and a
`bin/` full of stubs for `omarchy`, `pacman`, `xdg-settings` and `fc-cache`, so
runs are independent and leave nothing behind. `OMARCHY_PATH` points at
`tests/fixtures/omarchy`, a miniature copy of the real tree.

### Writing a test

Every suite sources `tests/helpers/env.sh`, which provides:

| Helper | Purpose |
|---|---|
| `test_case "name"` | start a case; counts it |
| `run_cli …` | run `bin/omarchy-browsers` in the sandbox, capture `$OUT` / `$STATUS` |
| `run_lib '…'` | source the libraries and run a snippet |
| `reset_state` | wipe config, fonts, fakes and the default browser |
| `fake_package`, `fake_command`, `fake_desktop` | simulate an installed browser |
| `set_default_desktop` | simulate a chosen default |
| `assert_eq`, `assert_contains`, `assert_not_contains` | comparisons |
| `assert_status`, `assert_file_exists`, `assert_file_missing` | state checks |
| `fail "why"` | fail the current case with a reason |
| `finish` | print the tally and exit non-zero on failure |

A good case is one assertion about one behaviour, with the reason spelled out:

```bash
test_case "remove refuses an unknown browser"
reset_state
run_cli remove netscape
assert_status 1 "$STATUS"
assert_contains "$OUT" "unknown browser: netscape"
```

Test the behaviour, not the wording, unless the wording is the contract users
rely on. When a message changes, grep for it — several suites pin exact strings.

### Registry changes

Two suites pin the registry contents, and the menu row count appears in a third:

```bash
grep -rn 'helium librewolf\|5 browsers\|15 menu rows\|"15"' tests/
```

Update them together with `lib/browsers.tsv` and follow
[docs/adding-a-browser.md](docs/adding-a-browser.md) — it lists each step,
including the checks to rehearse.

---

## Style

Bash with `set -euo pipefail`, four spaces, `snake_case` functions,
`UPPER_SNAKE` for exported and global variables. Beyond that:

- **Quote everything.** `"$var"`, `"${arr[@]}"`, `--` before paths.
- **Prefer builtins** over `sed`/`awk` when the job is a prefix or a suffix, but
  use `awk` for real line processing — the menu block inserter is intentionally
  `awk`.
- **`run_cmd` for anything that changes the system.** It is the only place that
  honours `--dry-run`; a mutation that bypasses it breaks the flag.
- **Fail with context.** `die "unknown browser: $name"` beats a bare `exit 1`.
- **Comment the why.** The code says what; a comment should explain the decision
  a future reader would otherwise reverse (the advance-width note in
  `assets/build-helium-icon-font.py` is the model).
- **No new dependencies.** Everything runs on what Omarchy and Arch already
  provide. `node` and `shellcheck` are optional and always degrade gracefully.

`shellcheck` should be clean. Where a warning is a deliberate choice, suppress it
at the line with a reason:

```bash
# shellcheck disable=SC2086 # deliberate word splitting on ':'
```

### Things that are invariants, not preferences

A change that breaks one of these is a bug regardless of intent:

1. Nothing under `/usr/share/omarchy` is written to.
2. `--dry-run` performs no writes, no `fc-cache`, no package operations.
3. Menu writes stay atomic and idempotent, and an invalid merge never replaces a
   valid file.
4. Purge paths stay relative to `$HOME`, free of `..`.
5. `uninstall.sh` only removes a link that points at this checkout.
6. Every glyph in the registry has a source: a Nerd Font codepoint, or a font in
   `assets/` that `menu setup` installs.

---

## Commits and pull requests

Commits follow [Conventional Commits](https://www.conventionalcommits.org/):
`feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`. Keep the subject under
72 characters and imperative — "add floorp row", not "added floorp row". Put the
reason in the body when it is not obvious.

A pull request should include:

- **What changed and why** — a paragraph is enough.
- **How you tested it** — the suites you ran, plus a manual check if the menu is
  involved. A screenshot of `Super+X › Install › Browser` is the most useful
  evidence for menu changes.
- **The environment** — `omarchy-browsers version` output for anything that
  depends on Omarchy's tree.

CI runs `bash -n`, `shellcheck` and `tests/run.sh` on Ubuntu with the same Bash
the tests expect. If CI is red, the fix belongs in the branch, not in a
follow-up.

### Changing the menu

Menu changes deserve a real check, not just green tests:

```bash
omarchy-browsers menu setup
omarchy-browsers menu status
# open Super+X › Install › Browser and look at it
omarchy-restart-shell     # if you touched the icon font
```

If you add an icon font, verify the glyph in the menu itself — a font preview
centres ink, the menu centres the advance box, and they disagree (see
[docs/helium-icon.md](docs/helium-icon.md)).

---

## Reporting bugs

Open an issue with:

```bash
omarchy-browsers version
omarchy-browsers doctor
omarchy-browsers menu status
```

For menu problems, include the block between the two marker comments from
`~/.config/omarchy/extensions/omarchy-menu.jsonc`, and say whether
`omarchy-restart-shell` changes anything.

---

## License

By contributing you agree your work is released under the [MIT
License](LICENSE). The Helium artwork in `assets/` is not MIT-licensed and
remains with the Helium project.
