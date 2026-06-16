#!/bin/bash
# omarchy-browser-support — Restore originals from omarchy git repo
# Usage: bash <(curl -sL https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/restore.sh)

OMARCHY_DIR="$HOME/.local/share/omarchy"
FILES=(
  omarchy-default-browser
  omarchy-install-browser
  omarchy-remove-browser
  omarchy-menu
  omarchy-launch-webapp
)

set -e

echo "╔══════════════════════════════════════════╗"
echo "║  Omarchy Browser Support — Restore       ║"
echo "╚══════════════════════════════════════════╝"
echo ""

if [[ ! -d "$OMARCHY_DIR/.git" ]]; then
  echo "ERROR: Omarchy git repo not found at $OMARCHY_DIR"
  echo "Cannot restore originals automatically."
  exit 1
fi

echo "==> Restoring original files from omarchy git repo..."
for file in "${FILES[@]}"; do
  if git -C "$OMARCHY_DIR" show HEAD:"bin/$file" >/dev/null 2>&1; then
    git -C "$OMARCHY_DIR" checkout -- "bin/$file"
    echo "    Restored $file"
  else
    echo "    WARNING: $file not found in git — skipping"
  fi
done

# Also clean up any leftover .bak files from previous installs
echo ""
echo "==> Cleaning up backup files..."
rm -f "$OMARCHY_DIR/bin/omarchy-default-browser.bak."*
rm -f "$OMARCHY_DIR/bin/omarchy-install-browser.bak."*
rm -f "$OMARCHY_DIR/bin/omarchy-remove-browser.bak."*
rm -f "$OMARCHY_DIR/bin/omarchy-menu.bak."*
rm -f "$OMARCHY_DIR/bin/omarchy-launch-webapp.bak."*
echo "    Removed backup files"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Done! Restart Walker:                  ║"
echo "║     omarchy restart walker               ║"
echo "╚══════════════════════════════════════════╝"
echo ""
