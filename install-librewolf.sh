#!/usr/bin/env bash
# Install LibreWolf only.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/core.sh"

install_browser "librewolf"
