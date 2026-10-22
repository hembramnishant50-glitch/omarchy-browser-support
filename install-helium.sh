#!/usr/bin/env bash
# Install Helium only.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/core.sh"

install_browser "helium"
