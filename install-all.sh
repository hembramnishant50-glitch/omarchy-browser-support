#!/usr/bin/env bash
# Install every extra browser (Helium, LibreWolf, Waterfox, Vivaldi).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/core.sh"

for name in "${NEW_BROWSER_NAMES[@]}"; do
  install_browser "$name"
  echo ""
done
