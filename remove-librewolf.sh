#!/bin/bash
# Omarchy Browser Support Pack — Remove LibreWolf Browser
# Usage: bash remove-librewolf.sh

set -e

echo "╔══════════════════════════════════════════════╗"
echo "║   Removing LibreWolf Browser                 ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

omarchy-remove-browser librewolf

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   Done! LibreWolf removed.                   ║"
echo "╚══════════════════════════════════════════════╝"
echo ""