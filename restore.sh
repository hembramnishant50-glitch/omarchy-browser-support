#!/bin/bash
# Omarchy Browser Support Pack — Uninstaller
# Removes the extra browser menu entries and all helper scripts.
# Usage: bash <(curl -sL https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/restore.sh)
#        bash restore.sh (from cloned repo)

MENU_DIR="$HOME/.config/omarchy/extensions"
MENU_FILE="omarchy-menu.jsonc"
BIN_DIR="$HOME/.local/bin"
SCRIPTS=(
  "omarchy-browser-select"
  "omarchy-browser-select-remove"
  "install-helium"
  "install-vivaldi"
  "install-floorp"
  "install-waterfox"
  "install-librewolf"
  "remove-helium"
  "remove-vivaldi"
  "remove-floorp"
  "remove-waterfox"
  "remove-librewolf"
)

set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║        Omarchy Browser Support Pack — Uninstaller              ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Restore menu extension from backup if exists
BACKUP_FILE=$(ls -t "$MENU_DIR/$MENU_FILE.bak."* 2>/dev/null | head -1)
if [[ -n "$BACKUP_FILE" ]]; then
  cp "$BACKUP_FILE" "$MENU_DIR/$MENU_FILE"
  rm -f "$MENU_DIR/$MENU_FILE.bak."*
  echo "==> Restored original $MENU_FILE from backup"
elif [[ -f "$MENU_DIR/$MENU_FILE" ]]; then
  rm -f "$MENU_DIR/$MENU_FILE"
  echo "==> Removed $MENU_FILE"
else
  echo "==> Menu extension not found — skipping"
fi

# Remove all helper scripts
for script in "${SCRIPTS[@]}"; do
  if [[ -f "$BIN_DIR/$script" ]]; then
    rm -f "$BIN_DIR/$script"
    echo "==> Removed $script"
  fi
done

echo ""
echo "==> Refreshing menu..."
omarchy menu refresh 2>/dev/null || true

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║   Done! Everything removed.                                    ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""