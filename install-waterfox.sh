#!/usr/bin/env bash
# Install Waterfox only.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/core.sh"

install_browser "waterfox"
