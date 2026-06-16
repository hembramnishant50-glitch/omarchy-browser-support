#!/bin/bash
# omarchy-browser-support — Restore originals
# Finds and restores .bak files, removes patched scripts
# Usage: bash <(curl -sL https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/restore.sh)

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
echo "║  Omarchy Browser Support — Restore       ║"
echo "╚══════════════════════════════════════════╝"
echo ""

restored=0
for file in "${FILES[@]}"; do
  target="$INSTALL_DIR/$file"
  backup=$(ls -1t "$target.bak."* 2>/dev/null | head -1)

  if [[ -n $backup && -f $backup ]]; then
    cp "$backup" "$target"
    rm "$backup"
    echo "    Restored $file"
    ((restored++))
  elif [[ -f $target ]]; then
    echo "    WARNING: No backup found for $file — skipping"
  else
    echo "    WARNING: $file not found — skipping"
  fi
done

if ((restored == 0)); then
  echo ""
  echo "  No backups found. Nothing to restore."
  echo ""
  exit 1
fi

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Done! Restart Walker:                  ║"
echo "║     omarchy restart walker               ║"
echo "╚══════════════════════════════════════════╝"
echo ""
