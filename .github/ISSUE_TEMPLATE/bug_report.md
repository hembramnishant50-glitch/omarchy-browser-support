---
name: Bug report
about: Something is broken — a command, the menu, or a browser install
title: ""
labels: bug
assignees: ""
---

## What happened

<!-- A sentence or two. What did you expect, and what did you get? -->

## How to reproduce

```bash
# the exact commands, in order
```

## Diagnostics

Paste the output of all three:

```bash
omarchy-browsers version
omarchy-browsers doctor
omarchy-browsers menu status
```

<details>
<summary>doctor output</summary>

```text

```

</details>

## Menu block (only if the menu is involved)

From `~/.config/omarchy/extensions/omarchy-menu.jsonc`, paste everything between
the two markers:

```jsonc
// >>> omarchy-browser-support

// <<< omarchy-browser-support
```

## Environment

- Omarchy version (`omarchy-version` or the `version` command above):
- Browser involved, if any:
- Did `omarchy-restart-shell` change anything?
- Fresh install, or an upgrade from the pre-1.0 scripts?

## Anything else

<!-- Screenshots of Super+X › Install › Browser help a lot for menu issues. -->
