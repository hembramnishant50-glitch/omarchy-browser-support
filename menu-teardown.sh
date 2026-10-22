#!/usr/bin/env bash
#
# Remove the extra-browser rows from Omarchy's menu.
# Installed browsers are NOT touched — only the menu entries go away.

set -euo pipefail

MENU_FILE="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
BEGIN_MARK="// >>> omarchy-browsers (managed block — regenerate with menu-setup.sh)"
END_MARK="// <<< omarchy-browsers"

if [[ ! -f $MENU_FILE ]] || ! grep -qF "$BEGIN_MARK" "$MENU_FILE"; then
  echo "No omarchy-browsers menu block found — nothing to do."
  exit 0
fi

sed -i "\|^[[:space:]]*$BEGIN_MARK|,\|^[[:space:]]*$END_MARK|d" "$MENU_FILE"

# Remove the custom icon font this project installed (Helium's starburst
# glyph lives in it — the rows that used it are already gone above).
ICON_FONT_DST="$HOME/.local/share/fonts/OmarchyHeliumIcon.ttf"
if [[ -f $ICON_FONT_DST ]]; then
  rm -f "$ICON_FONT_DST"
  fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1 || true
  echo "Removed the OmarchyHeliumIcon font from ~/.local/share/fonts"
fi

echo "Removed the extra-browser rows from $MENU_FILE"
echo "(Menu hot-reloads on save; installed browsers are untouched.)"
