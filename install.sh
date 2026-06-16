#!/bin/bash
# omarchy-browser-support — Installer
# Backs up originals, applies browser patches
# Usage: bash <(curl -sL https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/install.sh)

REPO="https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main"
FILES=(
  omarchy-default-browser
  omarchy-install-browser
  omarchy-remove-browser
  omarchy-menu
  omarchy-launch-webapp
)
INSTALL_DIR="$HOME/.local/share/omarchy/bin"

set -e

echo "╔══════════════════════════════════════════╗"
echo "║   Omarchy Browser Support — Installer    ║"
echo "╚══════════════════════════════════════════╝"
echo ""

echo "==> Downloading patched files..."
mkdir -p /tmp/omarchy-browser-patch
cd /tmp/omarchy-browser-patch

for file in "${FILES[@]}"; do
  echo -n "    $file ... "
  curl -sLO "$REPO/$file"
  chmod +x "$file"
  echo "OK"
done

echo ""
echo "==> Backing up originals..."
mkdir -p "$INSTALL_DIR"
for file in "${FILES[@]}"; do
  if [[ -f "$INSTALL_DIR/$file" ]]; then
    backup="$INSTALL_DIR/$file.bak.$(date +%s)"
    cp "$INSTALL_DIR/$file" "$backup"
    echo "    $file → $(basename $backup)"
  fi
done

echo ""
echo "==> Installing patched files..."
for file in "${FILES[@]}"; do
  cp "$file" "$INSTALL_DIR/$file"
  echo "    Installed $file"
done

echo ""
echo "==> Cleaning up..."
rm -rf /tmp/omarchy-browser-patch

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Done! Restart Walker:                  ║"
echo "║     omarchy restart walker               ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "  To restore originals later:"
echo "    bash <(curl -sL $REPO/restore.sh)"
echo ""
