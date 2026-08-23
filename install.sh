#!/bin/bash
# omarchy-browser-support — Installer
# Patches browser scripts + installs Quickshell menu extension
# Usage: bash <(curl -sL https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main/install.sh)

REPO="https://raw.githubusercontent.com/hembramnishant50-glitch/omarchy-browser-support/main"

# Scripts to patch (installed to /usr/bin or ~/.local/share/omarchy/bin)
SCRIPTS=(
  omarchy-default-browser
  omarchy-install-browser
  omarchy-remove-browser
  omarchy-launch-webapp
)

# Quickshell menu extension files
MENU_FILES=(
  omarchy-browser-menu.jsonc
  omarchy-browser-menu-provider
  omarchy-browser-install-provider
  omarchy-browser-remove-provider
)

# Detect install location for scripts
if [[ -L /usr/share/omarchy/bin/omarchy-default-browser ]] || [[ -f /usr/bin/omarchy-default-browser ]]; then
  SCRIPT_DIR="/usr/bin"
elif [[ -d "$HOME/.local/share/omarchy/bin" ]]; then
  SCRIPT_DIR="$HOME/.local/share/omarchy/bin"
else
  SCRIPT_DIR="$HOME/.local/share/omarchy/bin"
fi

# Menu extension always goes to user config
MENU_DIR="$HOME/.config/omarchy/extensions"
PROVIDER_DIR="$HOME/.config/omarchy/providers"

set -e

echo "╔══════════════════════════════════════════════╗"
echo "║   Omarchy Browser Support — Installer        ║"
echo "║   12 browsers: Chromium, Chrome, Brave,      ║"
echo "║   Brave Origin, Edge, Vivaldi, Firefox,      ║"
echo "║   Zen, Helium, Floorp, Waterfox, LibreWolf   ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  Scripts:  $SCRIPT_DIR"
echo "  Menu:     $MENU_DIR"
echo "  Providers: $PROVIDER_DIR"
echo ""

echo "==> Downloading patched files..."
mkdir -p /tmp/omarchy-browser-patch
cd /tmp/omarchy-browser-patch

for file in "${SCRIPTS[@]}" "${MENU_FILES[@]}"; do
  echo -n "    $file ... "
  curl -sLO "$REPO/$file"
  chmod +x "$file"
  echo "OK"
done

echo ""
echo "==> Backing up originals..."
for file in "${SCRIPTS[@]}"; do
  if [[ -f "$SCRIPT_DIR/$file" ]]; then
    backup="$SCRIPT_DIR/$file.bak.$(date +%s)"
    if [[ "$SCRIPT_DIR" == "/usr/bin" ]]; then
      sudo cp "$SCRIPT_DIR/$file" "$backup"
    else
      cp "$SCRIPT_DIR/$file" "$backup"
    fi
    echo "    $file → $(basename $backup)"
  fi
done

echo ""
echo "==> Installing patched scripts..."
for file in "${SCRIPTS[@]}"; do
  if [[ "$SCRIPT_DIR" == "/usr/bin" ]]; then
    sudo cp "$file" "$SCRIPT_DIR/$file"
  else
    cp "$file" "$SCRIPT_DIR/$file"
  fi
  echo "    Installed $file"
done

echo ""
echo "==> Installing Quickshell menu extension..."
mkdir -p "$MENU_DIR" "$PROVIDER_DIR"

# Back up existing menu extension if present
if [[ -f "$MENU_DIR/omarchy-browser-menu.jsonc" ]]; then
  cp "$MENU_DIR/omarchy-browser-menu.jsonc" "$MENU_DIR/omarchy-browser-menu.jsonc.bak.$(date +%s)"
fi

# Install JSONC menu extension
cp omarchy-browser-menu.jsonc "$MENU_DIR/omarchy-browser-menu.jsonc"
echo "    Installed omarchy-browser-menu.jsonc"

# Install provider scripts
for provider in omarchy-browser-menu-provider omarchy-browser-install-provider omarchy-browser-remove-provider; do
  cp "$provider" "$PROVIDER_DIR/$provider"
  chmod +x "$PROVIDER_DIR/$provider"
  echo "    Installed $provider"
done

echo ""
echo "==> Cleaning up..."
rm -rf /tmp/omarchy-browser-patch

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   Done! Restart Shell:                       ║"
echo "║     omarchy restart shell                    ║"
echo "║     omarchy menu refresh                     ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  To restore originals:"
echo "    bash <(curl -sL $REPO/restore.sh)"
echo "  or reinstall the omarchy package:"
echo "    sudo pacman -S omarchy"
echo ""
