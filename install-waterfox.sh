#!/bin/bash
# Omarchy Browser Support Pack — Install Waterfox Browser
# Usage: bash install-waterfox.sh

set -e

echo "╔══════════════════════════════════════════════╗"
echo "║   Installing Waterfox Browser                ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

omarchy-install-browser waterfox

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   Done! Waterfox installed.                  ║"
echo "║   Set as default: Setup > Defaults > Browser ║"
echo "╚══════════════════════════════════════════════╝"
echo ""