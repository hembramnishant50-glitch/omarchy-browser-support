#!/bin/bash
# Omarchy Browser Support Pack — Installer
# Adds 5 extra browsers (Vivaldi, Helium, Floorp, Waterfox, LibreWolf) to the Omarchy menu.
# Usage: bash <(curl -sL https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/install.sh)
#        bash install.sh (from cloned repo)

REPO="https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main"
MENU_DIR="$HOME/.config/omarchy/extensions"
MENU_FILE="omarchy-menu.jsonc"
BIN_DIR="$HOME/.local/bin"
SCRIPTS=(
  "omarchy-browser-select"
  "omarchy-browser-select-remove"
  "install-helium.sh"
  "install-vivaldi.sh"
  "install-floorp.sh"
  "install-waterfox.sh"
  "install-librewolf.sh"
  "remove-helium.sh"
  "remove-vivaldi.sh"
  "remove-floorp.sh"
  "remove-waterfox.sh"
  "remove-librewolf.sh"
)

set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║        Omarchy Browser Support Pack — Installer                ║"
echo "║   󰀙 Vivaldi   󰀘 Helium   󰈹 Floorp   󰈹 Waterfox   󰈹 LibreWolf   ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Detect if running from repo or curl
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
USE_LOCAL=false
if [[ -f "$SCRIPT_DIR/$MENU_FILE" ]]; then
  USE_LOCAL=true
fi

echo "==> Installing menu extension..."
mkdir -p "$MENU_DIR"
if [[ -f "$MENU_DIR/$MENU_FILE" ]]; then
  cp "$MENU_DIR/$MENU_FILE" "$MENU_DIR/$MENU_FILE.bak.$(date +%s)"
  echo "    Backed up existing extension"
fi

if [[ "$USE_LOCAL" == "true" ]]; then
  cp "$SCRIPT_DIR/$MENU_FILE" "$MENU_DIR/$MENU_FILE"
else
  mkdir -p /tmp/omarchy-browser-patch
  cd /tmp/omarchy-browser-patch
  curl -sLO "$REPO/$MENU_FILE"
  cp "$MENU_FILE" "$MENU_DIR/$MENU_FILE"
  rm -rf /tmp/omarchy-browser-patch
fi
echo "    Installed $MENU_FILE"

echo ""
echo "==> Installing helper scripts..."
mkdir -p "$BIN_DIR"
for script in "${SCRIPTS[@]}"; do
  if [[ "$USE_LOCAL" == "true" ]]; then
    cp "$SCRIPT_DIR/$script" "$BIN_DIR/${script%.sh}"
  else
    mkdir -p /tmp/omarchy-browser-patch
    cd /tmp/omarchy-browser-patch
    curl -sLO "$REPO/$script"
    cp "$script" "$BIN_DIR/${script%.sh}"
    rm -rf /tmp/omarchy-browser-patch
  fi
  chmod +x "$BIN_DIR/${script%.sh}"
done
echo "    Installed ${#SCRIPTS[@]} scripts to $BIN_DIR"

echo ""
echo "==> Refreshing menu..."
omarchy menu refresh 2>/dev/null || true

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║   Done! The 5 extra browsers now appear in:                    ║"
echo "║   Setup > Defaults > Browser   󰍜                             ║"
echo "║   Install > Browser            󰉉                             ║"
echo "║   Remove > Browser             󰭌                             ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "  Individual installers (run directly):"
echo "    install-helium       install-vivaldi       install-floorp"
echo "    install-waterfox     install-librewolf"
echo ""
echo "  Individual removers (run directly):"
echo "    remove-helium        remove-vivaldi        remove-floorp"
echo "    remove-waterfox      remove-librewolf"
echo ""
echo "  Quick menu pickers:"
echo "    omarchy-browser-select       # pick & install one browser"
echo "    omarchy-browser-select-remove # pick & remove one browser"
echo ""
echo "  To uninstall everything:"
echo "    bash restore.sh"
echo "    # or from curl:"
echo "    bash <(curl -sL $REPO/restore.sh)"
echo ""