#!/bin/bash
# omarchy-browser-support — Restore originals
# Usage: bash <(curl -sL https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/restore.sh)

SCRIPTS=(
  omarchy-default-browser
  omarchy-install-browser
  omarchy-remove-browser
  omarchy-launch-webapp
)

MENU_DIR="$HOME/.config/omarchy/extensions"
MENU_FILE="omarchy-browser-menu.jsonc"

set -e

echo "╔══════════════════════════════════════════════╗"
echo "║  Omarchy Browser Support — Restore           ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Detect script install location
if [[ -L /usr/share/omarchy/bin/omarchy-default-browser ]] || [[ -f /usr/bin/omarchy-default-browser ]]; then
  SCRIPT_DIR="/usr/bin"
elif [[ -d "$HOME/.local/share/omarchy/bin" ]]; then
  SCRIPT_DIR="$HOME/.local/share/omarchy/bin"
else
  echo "ERROR: Cannot detect Omarchy installation."
  exit 1
fi

echo "  Scripts:   $SCRIPT_DIR"
echo "  Menu ext:  $MENU_DIR"
echo ""

# Restore scripts
if [[ -d "$HOME/.local/share/omarchy/.git" ]]; then
  echo "==> Restoring scripts from git repo..."
  for file in "${SCRIPTS[@]}"; do
    if git -C "$HOME/.local/share/omarchy" show HEAD:"bin/$file" >/dev/null 2>&1; then
      git -C "$HOME/.local/share/omarchy" checkout -- "bin/$file"
      echo "    Restored $file"
    fi
  done
else
  echo "==> Package-based installation detected."
  for file in "${SCRIPTS[@]}"; do
    if [[ -f "/usr/share/omarchy/bin/$file" ]]; then
      if [[ "$SCRIPT_DIR" == "/usr/bin" ]]; then
        sudo cp "/usr/share/omarchy/bin/$file" "$SCRIPT_DIR/$file"
      else
        cp "/usr/share/omarchy/bin/$file" "$SCRIPT_DIR/$file"
      fi
      echo "    Restored $file"
    else
      echo "    WARNING: /usr/share/omarchy/bin/$file not found — reinstall package"
    fi
  done
fi

# Remove browser menu extension
echo ""
echo "==> Removing browser menu extension..."
rm -f "$MENU_DIR/$MENU_FILE"
echo "    Removed $MENU_FILE"

# Clean up backup files
echo ""
echo "==> Cleaning up backup files..."
for file in "${SCRIPTS[@]}"; do
  rm -f "$SCRIPT_DIR/$file.bak."* 2>/dev/null
done
rm -f "$MENU_DIR/$MENU_FILE.bak."* 2>/dev/null
echo "    Done"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   Done! Restart Shell:                       ║"
echo "║     omarchy restart shell                    ║"
echo "║     omarchy menu refresh                     ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
