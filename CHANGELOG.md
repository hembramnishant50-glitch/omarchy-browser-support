# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Nothing yet.

## [1.0.0] — 2026-10-28

The first release of the rewritten tool. The pre-1.0 tree was thirteen
near-identical shell scripts (`install-helium.sh`, `remove-vivaldi.sh`,
`menu-setup.sh`, …) that had drifted apart. 1.0 replaces them with one
dispatcher and a single registry.

### Added

- **`omarchy-browsers`** — one command for `install`, `remove`, `default`,
  `status [--json]`, `list`, `menu setup|teardown|status`, `doctor`, `version`
  and `help`.
- **`lib/browsers.tsv`** — a 10-column registry that drives every installer,
  remover, menu row, status field and diagnostic. Adding a browser is one line.
- **Helium as the flagship.** Its menu rows carry the real starburst from the
  official app icon, rendered by the bundled `OmarchyHeliumIcon` font
  (`assets/OmarchyHeliumIcon.ttf`, glyph `U+E00B`), and the icon is installed
  and cached automatically by `menu setup`.
- **`doctor`** — checks the Bash version, the Omarchy tree, the registry, the
  menu block, the icon font, the default browser, every installed browser and
  AUR reachability, with `ok` / `warn` / `fail` output and a meaningful exit
  code.
- **`status --json`** — a small stable schema (`schema: 1`) for scripts.
- **Dry runs** — `--dry-run` works before or after the subcommand on every
  mutating operation.
- **A hermetic test suite** — 9 suites, 155 checks, covering the CLI, registry
  validation, install/remove/default, desktop detection, menu generation and
  teardown, the installer scripts and `doctor`. No test touches the real system
  or requires Omarchy to be installed.
- **Documentation** — architecture, the registry contract, a step-by-step guide
  to adding a browser, a troubleshooting matrix and a note on the icon font.
- **CI** — `shellcheck` and `bash -n` over every script plus the full test
  suite on every push and pull request.

### Changed

- Menu handling is now atomic and idempotent: the block is regenerated from the
  registry, written with `mktemp` + `mv`, skipped when nothing changed, and
  validated against Omarchy's own `MenuModel.js` before it replaces the live
  file.
- `install.sh` links the CLI into `~/.local/bin` instead of copying files, so
  `git pull` updates the tool in place. `uninstall.sh` removes the link only
  when it points back at this checkout.
- The menu block now carries a version-agnostic marker pair, and pre-1.0 blocks
  are stripped on upgrade instead of accumulating.
- Fonts an older version installed but the registry no longer asks for are
  pruned by `menu setup`.

### Fixed

- Chromium-based browsers no longer share a generic globe: Helium has its own
  glyph and family.
- Removing a browser hands the default role to an installed survivor instead of
  leaving `http(s)` unowned.
- Purge paths are validated at load time — absolute paths and `..` are rejected,
  so `--purge` cannot escape `$HOME`.

### Removed

- The thirteen per-browser scripts, superseded by the dispatcher and registry.

[Unreleased]: https://github.com/hembramnishant50-glitch/omarchy-browser-support/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/hembramnishant50-glitch/omarchy-browser-support/releases/tag/v1.0.0
