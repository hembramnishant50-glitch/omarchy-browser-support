#!/usr/bin/env bash
# Remove Waterfox. Pass --purge to also delete its profile/config data.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/core.sh"

remove_browser "waterfox" "${1:-}"
