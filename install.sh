#!/bin/bash
# Omarchy Browser Support Pack — Installer
# Adds 5 extra browsers (Vivaldi, Helium, Floorp, Waterfox, LibreWolf) to the Omarchy menu.
# Usage: bash install.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MENU_DIR="$HOME/.config/omarchy/extensions"
MENU_FILE="omarchy-browser-menu.jsonc"
BIN_DIR="$HOME/.local/bin"
SELECTORS=("omarchy-browser-select" "omarchy-browser-select-remove")

set -e

echo "╔══════════════════════════════════════════════╗"
echo "║   Omarchy Browser Support — Installer        ║"
echo "║   Adds to menu: Vivaldi, Helium, Floorp,     ║"
echo "║   Waterfox, LibreWolf                        ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

echo "==> Installing menu extension..."
mkdir -p "$MENU_DIR"
if [[ -f "$MENU_DIR/$MENU_FILE" ]]; then
  cp "$MENU_DIR/$MENU_FILE" "$MENU_DIR/$MENU_FILE.bak.$(date +%s)"
  echo "    Backed up existing extension"
fi
cp "$SCRIPT_DIR/$MENU_FILE" "$MENU_DIR/$MENU_FILE"
echo "    Installed $MENU_FILE"

echo ""
echo "==> Installing selector scripts..."
mkdir -p "$BIN_DIR"
for sel in "${SELECTORS[@]}"; do
  cp "$SCRIPT_DIR/$sel" "$BIN_DIR/$sel"
  chmod +x "$BIN_DIR/$sel"
  echo "    Installed $sel → $BIN_DIR"
done

echo ""
echo "==> Refreshing menu..."
omarchy menu refresh 2>/dev/null || true

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   Done! The 5 extra browsers now appear in:  ║"
echo "║   Setup > Defaults > Browser                 ║"
echo "║   Install > Browser                          ║"
echo "║   Remove > Browser                           ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  Install Browser: opens a picker to install one browser"
echo "  Individual entries: click to install/remove directly"
echo ""
echo "  To uninstall: bash restore.sh"
echo ""
