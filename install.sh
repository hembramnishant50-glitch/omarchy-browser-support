#!/usr/bin/env bash
#
# install.sh — put `omarchy-browsers` on your PATH and wire up the menu.
#
#   ./install.sh                 link into ~/.local/bin, then `menu setup`
#   ./install.sh --no-menu       only create the symlink
#   ./install.sh --bin-dir DIR   link somewhere else
#   ./install.sh --dry-run       show what would happen
#
# Nothing is copied: the symlink points back at this checkout, so `git pull`
# updates the CLI in place. Re-run `menu setup` after moving the checkout,
# because menu rows embed the dispatcher's absolute path.

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BIN_SRC="$ROOT/bin/omarchy-browsers"
PROG='install.sh'

BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
DO_MENU=1
DRY_RUN=''

usage() {
  sed -n '2,10p' "$0" | sed -E 's/^# ?//'
}

while (( $# > 0 )); do
  case $1 in
  --no-menu) DO_MENU=0 ;;
  --bin-dir)
    [[ -n ${2:-} ]] || { printf '%s: --bin-dir needs a path\n' "$PROG" >&2; exit 2; }
    BIN_DIR=$2
    shift
    ;;
  --bin-dir=*) BIN_DIR=${1#*=} ;;
  --dry-run) DRY_RUN=1 ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    printf '%s: unknown option: %s\n' "$PROG" "$1" >&2
    usage >&2
    exit 2
    ;;
  esac
  shift
done

say() { printf '%s\n' "$*"; }
dry() { [[ -n $DRY_RUN ]] && printf '[dry-run] %s\n' "$*"; }

[[ -x $BIN_SRC ]] || { printf '%s: missing executable: %s\n' "$PROG" "$BIN_SRC" >&2; exit 1; }

LINK="$BIN_DIR/omarchy-browsers"

# ---------------------------------------------------------------------------
# 1. The symlink
# ---------------------------------------------------------------------------

say "Linking $LINK → $BIN_SRC"

if [[ -L $LINK && $(readlink -f -- "$LINK" 2>/dev/null || true) == "$(readlink -f -- "$BIN_SRC")" ]]; then
  say "  already linked."
elif [[ -e $LINK && ! -L $LINK ]]; then
  printf '%s: %s already exists and is not a symlink — move it aside first.\n' \
    "$PROG" "$LINK" >&2
  exit 1
else
  if [[ -n $DRY_RUN ]]; then
    dry "mkdir -p $BIN_DIR"
    dry "ln -sfn $BIN_SRC $LINK"
  else
    mkdir -p -- "$BIN_DIR"
    ln -sfn -- "$BIN_SRC" "$LINK"
    say "  linked."
  fi
fi

case ":$PATH:" in
*":$BIN_DIR:"*) ;;
*) say "  note: $BIN_DIR is not on your PATH — add it in your shell profile." ;;
esac

# ---------------------------------------------------------------------------
# 2. The menu
# ---------------------------------------------------------------------------

if (( DO_MENU )); then
  say
  say "Installing the Omarchy menu rows…"
  if [[ -n $DRY_RUN ]]; then
    DRY_RUN=1 "$BIN_SRC" menu setup
  else
    "$BIN_SRC" menu setup
  fi
else
  say
  say "Skipped the menu (--no-menu). Run 'omarchy-browsers menu setup' when ready."
fi

# ---------------------------------------------------------------------------
# 3. What next
# ---------------------------------------------------------------------------

say
say "Done. Useful next steps:"
say "  omarchy-browsers status      # what is installed, and the default"
say "  omarchy-browsers doctor      # full environment check"
say "  omarchy-browsers install helium"
say
say "The menu lives at Super+X › Install › Browser."
