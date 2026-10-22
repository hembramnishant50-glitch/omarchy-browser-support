#!/usr/bin/env bash
# Remove every extra browser this project manages.
# Pass --purge to also delete their profile/config data.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/core.sh"

purge=""
[[ ${1:-} == "--purge" ]] && purge="--purge"

# Reverse order so the last-installed-looking browser goes first.
for ((i = ${#NEW_BROWSER_NAMES[@]} - 1; i >= 0; i--)); do
  remove_browser "${NEW_BROWSER_NAMES[$i]}" "$purge"
  echo ""
done
