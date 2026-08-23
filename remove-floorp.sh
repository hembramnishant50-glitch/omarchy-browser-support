#!/bin/bash
# Omarchy Browser Support Pack — Remove Floorp Browser
# Usage: bash remove-floorp.sh

set -e

echo "╔══════════════════════════════════════════════╗"
echo "║   Removing Floorp Browser                    ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

omarchy-remove-browser floorp

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   Done! Floorp removed.                      ║"
echo "╚══════════════════════════════════════════════╝"
echo ""