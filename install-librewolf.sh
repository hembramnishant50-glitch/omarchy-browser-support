#!/bin/bash
# Omarchy Browser Support Pack — Install LibreWolf Browser
# Usage: bash install-librewolf.sh

set -e

echo "╔══════════════════════════════════════════════╗"
echo "║   Installing LibreWolf Browser               ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

omarchy-install-browser librewolf

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   Done! LibreWolf installed.                 ║"
echo "║   Set as default: Setup > Defaults > Browser ║"
echo "╚══════════════════════════════════════════════╝"
echo ""