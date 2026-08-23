#!/bin/bash
# Omarchy Browser Support Pack — Install Helium Browser
# Usage: bash install-helium.sh

set -e

echo "╔══════════════════════════════════════════════╗"
echo "║   Installing Helium Browser                  ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

omarchy-install-browser helium

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   Done! Helium installed.                    ║"
echo "║   Set as default: Setup > Defaults > Browser ║"
echo "╚══════════════════════════════════════════════╝"
echo ""