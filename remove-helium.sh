#!/bin/bash
# Omarchy Browser Support Pack — Remove Helium Browser
# Usage: bash remove-helium.sh

set -e

echo "╔══════════════════════════════════════════════╗"
echo "║   Removing Helium Browser                    ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

omarchy-remove-browser helium

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   Done! Helium removed.                      ║"
echo "╚══════════════════════════════════════════════╝"
echo ""