#!/bin/bash
# Omarchy Browser Support Pack — Install Floorp Browser
# Usage: bash install-floorp.sh

set -e

echo "╔══════════════════════════════════════════════╗"
echo "║   Installing Floorp Browser                  ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

omarchy-install-browser floorp

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   Done! Floorp installed.                    ║"
echo "║   Set as default: Setup > Defaults > Browser ║"
echo "╚══════════════════════════════════════════════╝"
echo ""