#!/bin/bash
# Omarchy Browser Support Pack — Uninstaller
# Removes the extra browser menu entries and selector scripts.
# Usage: bash restore.sh

MENU_DIR="$HOME/.config/omarchy/extensions"
MENU_FILE="omarchy-browser-menu.jsonc"
BIN_DIR="$HOME/.local/bin"
SELECTORS=("omarchy-browser-select" "omarchy-browser-select-remove")

set -e

echo "╔══════════════════════════════════════════════╗"
echo "║   Omarchy Browser Support — Uninstaller      ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

if [[ -f "$MENU_DIR/$MENU_FILE" ]]; then
  rm -f "$MENU_DIR/$MENU_FILE"
  echo "==> Removed $MENU_FILE"
else
  echo "==> Menu extension not found — skipping"
fi

rm -f "$MENU_DIR/$MENU_FILE.bak."* 2>/dev/null

for sel in "${SELECTORS[@]}"; do
  if [[ -f "$BIN_DIR/$sel" ]]; then
    rm -f "$BIN_DIR/$sel"
    echo "==> Removed $sel"
  fi
done

echo ""
echo "==> Refreshing menu..."
omarchy menu refresh 2>/dev/null || true

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   Done! Everything removed.                  ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
