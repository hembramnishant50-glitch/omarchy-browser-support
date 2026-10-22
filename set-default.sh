#!/usr/bin/env bash
#
# Make any browser the default — the extra ones AND Omarchy's stock six.
#
#   ./set-default.sh <browser>          set the default browser
#   ./set-default.sh <browser> --check  exit 0 when <browser> is the default
#                                       (used by the menu's ✓ marks)
#   ./set-default.sh                    show current default + status table

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/core.sh"

args=()
check=false
for a in "$@"; do
  case $a in
  --check) check=true ;;
  --list | --status) args=() ;;
  -*) die "unknown option: $a" ;;
  *) args+=("$a") ;;
  esac
done

if (( ${#args[@]} == 0 )); then
  print_default_status
  exit 0
fi

name=${args[0]}

if $check; then
  check_default "$name"
else
  if ! is_stock_browser "$name" && ! is_new_browser "$name"; then
    die "unknown browser '$name'. Known: ${NEW_BROWSER_NAMES[*]} (plus stock: ${!STOCK_BROWSER_DESKTOP[*]})"
  fi
  set_default_browser "$name"
fi
