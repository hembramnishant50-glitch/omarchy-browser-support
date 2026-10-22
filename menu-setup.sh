#!/usr/bin/env bash
#
# Add the extra browsers to Omarchy's menu:
#   Install  > Browser        (shown only while the browser is missing)
#   Remove   > Browser        (shown only while the browser is installed)
#   Setup > Defaults > Browser (shown only when the browser's command exists)
#
# Idempotent: the rows live in a marked block inside
# ~/.config/omarchy/extensions/omarchy-menu.jsonc and are regenerated on
# every run. That file hot-reloads on save — no shell restart needed.

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/core.sh"

MENU_FILE="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
BEGIN_MARK="// >>> omarchy-browsers (managed block — regenerate with menu-setup.sh)"
END_MARK="// <<< omarchy-browsers"

mkdir -p "$(dirname "$MENU_FILE")"
touch "$MENU_FILE"

# Make sure the file is a JSONC object to merge into.
if ! grep -q '^[[:space:]]*{' "$MENU_FILE" && ! grep -q '^[[:space:]]*// ' "$MENU_FILE"; then
  printf '{\n}\n' >"$MENU_FILE"
elif ! grep -q '}' "$MENU_FILE"; then
  printf '\n}\n' >>"$MENU_FILE"
fi

# --- install the custom icon font ------------------------------------------
# Some rows point their `iconFont` at fonts built by this project (Helium's
# starburst comes from assets/build-helium-icon-font.py). The font must be
# present in fontconfig for the menu to render those glyphs.
ICON_FONT_SRC="$OMARCHY_BROWSERS_DIR/assets/OmarchyHeliumIcon.ttf"
ICON_FONT_DST="$HOME/.local/share/fonts/OmarchyHeliumIcon.ttf"
if [[ -f $ICON_FONT_SRC ]]; then
  if ! cmp -s "$ICON_FONT_SRC" "$ICON_FONT_DST" 2>/dev/null; then
    run_cmd install -Dm644 "$ICON_FONT_SRC" "$ICON_FONT_DST"
    run_cmd fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1 || warn "fc-cache failed — run it manually if icons are missing"
    info "installed icon font: OmarchyHeliumIcon"
  fi
else
  warn "icon font source missing ($ICON_FONT_SRC) — Helium rows may show a placeholder glyph"
fi

# --- strip any previous block ----------------------------------------------
sed -i "\|^[[:space:]]*$BEGIN_MARK|,\|^[[:space:]]*$END_MARK|d" "$MENU_FILE"

# --- build the new block ---------------------------------------------------
tmp_block=$(mktemp)
tmp_insert=$(mktemp)
trap 'rm -f "$tmp_block" "$tmp_insert"' EXIT

{
  echo "$BEGIN_MARK"
  echo "// Rows for the extra browsers managed by $OMARCHY_BROWSERS_DIR"
  echo "// Edit lib/core.sh + re-run menu-setup.sh instead of editing here."

  for name in "${NEW_BROWSER_NAMES[@]}"; do
    display=$(browser_display "$name")
    source_kind=$(browser_source "$name")
    cmd=$(browser_cmd "$name")
    glyph=$(browser_menu_glyph "$name")
    icon_font=$(browser_icon_font "$name")

    # MenuModel passes `iconFont` through to Menu.qml, which uses it as the
    # font family for the icon glyph. Rows without a custom font render the
    # icon in the menu's normal Nerd Font.
    icon_font_line=""
    [[ -n $icon_font ]] && icon_font_line="    \"iconFont\": \"$icon_font\",
"

    browser_pkgs "$name" pkgs
    primary=${pkgs[0]}

    script_dir=$OMARCHY_BROWSERS_DIR

    # Install > Browser — only when the package is missing
    echo "  \"install.browser.$name\": {"
    echo "    \"icon\": \"$glyph\","
    printf '%s' "$icon_font_line"
    echo "    \"label\": \"$display\","
    echo "    \"when\": \"! omarchy-pkg-present $primary\","
    echo "    \"action\": \"omarchy-launch-floating-terminal-with-presentation '$script_dir/install-$name.sh'\""
    echo "  },"

    # Remove > Browser — only when the package is present
    echo "  \"remove.browser.$name\": {"
    echo "    \"icon\": \"$glyph\","
    printf '%s' "$icon_font_line"
    echo "    \"label\": \"$display\","
    echo "    \"when\": \"omarchy-pkg-present $primary\","
    echo "    \"action\": \"omarchy-launch-floating-terminal-with-presentation '$script_dir/remove-$name.sh'\""
    echo "  },"

    # Setup > Defaults > Browser — only when the command exists
    echo "  \"setup.default.browser.$name\": {"
    echo "    \"icon\": \"$glyph\","
    printf '%s' "$icon_font_line"
    echo "    \"label\": \"$display\","
    echo "    \"when\": \"omarchy-cmd-present $cmd\","
    echo "    \"checked\": \"'$script_dir/set-default.sh' $name --check\","
    echo "    \"action\": \"'$script_dir/set-default.sh' $name\""
    echo "  },"

    info "menu rows ready: $display ($source_kind, $primary)" >&2
  done

  echo "$END_MARK"
} >"$tmp_block"

# --- insert the block before the file's final } ----------------------------
awk -v blk="$tmp_block" '
  { lines[NR] = $0 }
  END {
    last = NR
    while (last > 0 && lines[last] !~ /^[[:space:]]*\}/) last--
    if (last == 0) { print "error: no closing brace in menu file" > "/dev/stderr"; exit 1 }
    for (i = 1; i < last; i++) print lines[i]
    while ((getline l < blk) > 0) print l
    for (i = last; i <= NR; i++) print lines[i]
  }
' "$MENU_FILE" >"$tmp_insert"
mv "$tmp_insert" "$MENU_FILE"
trap 'rm -f "$tmp_block"' EXIT

# --- validate: the merged file must parse as JSONC -------------------------
if command -v node >/dev/null 2>&1; then
  MENU_FILE="$MENU_FILE" node -e '
    const m = require("/usr/share/omarchy/shell/plugins/menu/MenuModel.js");
    const fs = require("fs");
    const rows = m.parseMenuJsonc(fs.readFileSync(process.env.MENU_FILE, "utf8"));
    const names = ["helium","librewolf","waterfox","vivaldi"];
    const mine = rows.filter(r =>
      names.some(n => /^(install|remove)\.browser\.|^(setup\.)?default\.browser\./.test(r.id || "") && (r.id.endsWith("." + n)))
    );
    if (mine.length !== 12) {
      console.error(`validation failed: expected 12 rows, got ${mine.length}`);
      process.exit(1);
    }
    const helium = rows.filter(r => r.id && r.id.endsWith(".helium"));
    const badHelium = helium.filter(r => r.iconFont !== "OmarchyHeliumIcon");
    if (badHelium.length) {
      console.error(`validation failed: ${badHelium.length} helium rows missing iconFont`);
      process.exit(1);
    }
    console.log(`validated: ${mine.length} extra-browser rows parse correctly (helium iconFont ok)`);
  '
else
  warn "node not found — skipping JSONC validation (file written anyway)"
fi

echo ""
ok "Menu integration updated: $MENU_FILE"
echo "The menu hot-reloads — open it now (Super+X) to see the new rows."
