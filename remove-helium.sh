#!/usr/bin/env bash
# Remove Helium. Pass --purge to also delete its profile/config data.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/core.sh"

remove_browser "helium" "${1:-}"
