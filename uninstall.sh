#!/usr/bin/env bash
#
# uninstall.sh — remove the CLI link and the Omarchy menu rows.
#
#   ./uninstall.sh                remove the link and the menu rows
#   ./uninstall.sh --keep-menu    leave the menu integration alone
#   ./uninstall.sh --bin-dir DIR  look for the link somewhere else
#   ./uninstall.sh --dry-run      show what would happen
#
# Browsers are never uninstalled here: use `omarchy-browsers remove <name>`.
# The link is only removed when it points back at this checkout.

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BIN_SRC="$ROOT/bin/omarchy-browsers"
PROG='uninstall.sh'

BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
DO_MENU=1
DRY_RUN=''

usage() {
  sed -n '2,11p' "$0" | sed -E 's/^# ?//'
}

while (( $# > 0 )); do
  case $1 in
  --keep-menu) DO_MENU=0 ;;
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

LINK="$BIN_DIR/omarchy-browsers"

# ---------------------------------------------------------------------------
# 1. The menu (before the link goes away, since it calls the dispatcher)
# ---------------------------------------------------------------------------

if (( DO_MENU )) && [[ -x $BIN_SRC ]]; then
  say "Removing the Omarchy menu rows…"
  if [[ -n $DRY_RUN ]]; then
    DRY_RUN=1 "$BIN_SRC" menu teardown
  else
    "$BIN_SRC" menu teardown
  fi
  say
fi

# ---------------------------------------------------------------------------
# 2. The symlink
# ---------------------------------------------------------------------------

say "Checking $LINK"

if [[ -L $LINK ]] && [[ $(readlink -f -- "$LINK" 2>/dev/null || true) == "$(readlink -f -- "$BIN_SRC")" ]]; then
  if [[ -n $DRY_RUN ]]; then
    dry "rm -f $LINK"
  else
    rm -f -- "$LINK"
    say "  removed."
  fi
elif [[ -e $LINK || -L $LINK ]]; then
  say "  left alone: it does not point at this checkout."
else
  say "  nothing to remove."
fi

say
say "Done. Installed browsers and their profiles were not touched."
say "To remove a browser too:  $BIN_SRC remove <name> --purge"
