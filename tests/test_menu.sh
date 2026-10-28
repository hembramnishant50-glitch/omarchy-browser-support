#!/usr/bin/env bash
#
# Menu integration — the managed block, the icon font, and teardown.

source "$(dirname "${BASH_SOURCE[0]}")/helpers/env.sh"

MENU_FILE="$XDG_CONFIG_HOME/omarchy/extensions/omarchy-menu.jsonc"
FONT="$XDG_DATA_HOME/fonts/OmarchyHeliumIcon.ttf"

menu_rows() { grep -cE '"(install|remove)\.browser\.|"setup\.default\.browser\.' "$MENU_FILE"; }

# ---------------------------------------------------------------------------
echo "menu: setup"
# ---------------------------------------------------------------------------

test_case "setup creates the menu file and the rows"
reset_state
run_cli menu setup
assert_status 0 "$STATUS"
assert_file_exists "$MENU_FILE"
assert_eq "15" "$(menu_rows)" "5 browsers × 3 rows"
assert_contains "$OUT" "15 menu rows ready"

test_case "setup installs the bundled Helium icon font"
assert_file_exists "$FONT"
cmp -s "$ROOT/assets/OmarchyHeliumIcon.ttf" "$FONT" || fail "installed font differs from assets/"
assert_contains "$OUT" "installed menu icon font: OmarchyHeliumIcon"
assert_contains "$OUT" "restart the Omarchy shell"

test_case "the block is wrapped in markers"
assert_contains "$(cat "$MENU_FILE")" "// >>> omarchy-browser-support"
assert_contains "$(cat "$MENU_FILE")" "// <<< omarchy-browser-support"

test_case "helium rows use the real starburst and its icon font"
assert_contains "$(cat "$MENU_FILE")" '"install.browser.helium": {"icon": "", "iconFont": "OmarchyHeliumIcon",'
assert_contains "$(cat "$MENU_FILE")" '"iconFont": "OmarchyHeliumIcon"'
assert_eq "3" "$(grep -c '"iconFont": "OmarchyHeliumIcon"' "$MENU_FILE")"

test_case "other rows stay on their Nerd Font glyph"
assert_not_contains "$(grep '"install.browser.librewolf"' "$MENU_FILE")" 'iconFont'

test_case "setup restores a damaged icon font"
printf 'not a font\n' >"$FONT"
run_cli menu setup
assert_status 0 "$STATUS"
cmp -s "$ROOT/assets/OmarchyHeliumIcon.ttf" "$FONT" || fail "setup must rewrite a stale font"

test_case "rows point at this checkout's dispatcher"
assert_contains "$(cat "$MENU_FILE")" "$ROOT/bin/omarchy-browsers"

test_case "install rows hide once the package is present"
assert_contains "$(cat "$MENU_FILE")" '"when": "! omarchy-pkg-present helium-browser-bin"'

test_case "remove rows only show when installed"
assert_contains "$(cat "$MENU_FILE")" '"when": "omarchy-pkg-present helium-browser-bin"'

test_case "default rows are gated on the command and use --check"
assert_contains "$(cat "$MENU_FILE")" '"when": "omarchy-cmd-present helium-browser"'
assert_contains "$(cat "$MENU_FILE")" "\"checked\": \"'$ROOT/bin/omarchy-browsers' default helium --check\""

test_case "the generated file parses as JSONC"
run_lib 'validate_menu "$XDG_CONFIG_HOME/omarchy/extensions/omarchy-menu.jsonc"'
assert_status 0 "$STATUS"
assert_contains "$OUT" "validated 15 browser rows"

test_case "setup is idempotent"
before=$(md5sum <"$MENU_FILE")
run_cli menu setup
assert_status 0 "$STATUS"
assert_contains "$OUT" "already up to date"
assert_eq "$before" "$(md5sum <"$MENU_FILE")"

# ---------------------------------------------------------------------------
echo "menu: coexistence"
# ---------------------------------------------------------------------------

test_case "user rows outside the block are preserved"
reset_state
mkdir -p "$(dirname "$MENU_FILE")"
cat >"$MENU_FILE" <<'EOF'
{
  // my own tweaks
  "my.custom": {"label": "Mine", "action": "echo hi"}
}
EOF
run_cli menu setup
assert_status 0 "$STATUS"
assert_contains "$(cat "$MENU_FILE")" '"my.custom"'
assert_contains "$(cat "$MENU_FILE")" '// my own tweaks'
assert_eq "15" "$(menu_rows)"

test_case "a second setup keeps the user row exactly once"
run_cli menu setup
assert_eq "1" "$(grep -c '"my.custom"' "$MENU_FILE")"

test_case "a compact {} file is expanded before insertion"
reset_state
mkdir -p "$(dirname "$MENU_FILE")"
printf '{}\n' >"$MENU_FILE"
run_cli menu setup
assert_status 0 "$STATUS"
assert_eq "15" "$(menu_rows)"

test_case "a stale block is replaced, not duplicated"
reset_state
run_cli menu setup
sed -i 's/"label": "LibreWolf"/"label": "STALE"/' "$MENU_FILE"
run_cli menu setup
assert_contains "$(cat "$MENU_FILE")" '"label": "LibreWolf"'
assert_not_contains "$(cat "$MENU_FILE")" "STALE"
assert_eq "1" "$(grep -c '>>> omarchy-browser-support' "$MENU_FILE")"

test_case "the pre-1.0 menu block is migrated away"
reset_state
mkdir -p "$(dirname "$MENU_FILE")"
cat >"$MENU_FILE" <<'EOF'
{
// >>> omarchy-browsers (managed block — regenerate with menu-setup.sh)
  "install.browser.helium": {"label": "Old Helium"},
// <<< omarchy-browsers
}
EOF
run_cli menu setup
assert_status 0 "$STATUS"
assert_not_contains "$(cat "$MENU_FILE")" "menu-setup.sh"
assert_eq "1" "$(grep -c '"install.browser.helium"' "$MENU_FILE")"
assert_eq "15" "$(menu_rows)"

# ---------------------------------------------------------------------------
echo "menu: status and teardown"
# ---------------------------------------------------------------------------

test_case "status reports a live integration"
reset_state
run_cli menu setup
run_cli menu status
assert_status 0 "$STATUS"
assert_contains "$OUT" "managed block present (15 rows)"
assert_contains "$OUT" "icon font installed: OmarchyHeliumIcon"
assert_contains "$OUT" "validated 15 browser rows"

test_case "status warns when setup has not run"
reset_state
run_cli menu status
assert_status 0 "$STATUS"
assert_contains "$OUT" "managed block not installed"

test_case "teardown removes the block and the font"
reset_state
run_cli menu setup
run_cli menu teardown
assert_status 0 "$STATUS"
assert_contains "$OUT" "removed the managed rows"
assert_contains "$OUT" "removed menu icon font: OmarchyHeliumIcon"
assert_eq "0" "$(menu_rows || true)"
assert_file_missing "$FONT"
assert_contains "$(cat "$MENU_FILE")" "{"
assert_not_contains "$(cat "$MENU_FILE")" "omarchy-browser-support"

test_case "teardown keeps user rows"
reset_state
mkdir -p "$(dirname "$MENU_FILE")"
printf '{\n  "my.custom": {"label": "Mine"}\n}\n' >"$MENU_FILE"
run_cli menu setup
run_cli menu teardown
assert_contains "$(cat "$MENU_FILE")" '"my.custom"'

test_case "teardown never removes packages"
reset_state
fake_package helium-browser-bin
run_cli menu setup
run_cli menu teardown
assert_eq "" "$(cat "$TEST_STATE/pkg-drop.log" 2>/dev/null || true)"
assert_contains "$OUT" "Installed browsers were not touched"

test_case "teardown without an integration is harmless"
reset_state
run_cli menu teardown
assert_status 0 "$STATUS"
assert_contains "$OUT" "no menu file"

test_case "menu with no action is a usage error"
run_cli menu
assert_status 2 "$STATUS"
assert_contains "$OUT" "menu needs an action"

test_case "an unknown menu action is a usage error"
run_cli menu explode
assert_status 2 "$STATUS"

# ---------------------------------------------------------------------------
echo "menu: dry-run"
# ---------------------------------------------------------------------------

test_case "--dry-run writes nothing"
reset_state
run_cli --dry-run menu setup
assert_status 0 "$STATUS"
assert_contains "$OUT" "would write the managed block"
assert_file_missing "$MENU_FILE"
assert_file_missing "$FONT"

test_case "--dry-run teardown writes nothing"
reset_state
run_cli menu setup
mkdir -p "$XDG_DATA_HOME/fonts"
: >"$FONT"
before=$(md5sum <"$MENU_FILE")
run_cli --dry-run menu teardown
assert_eq "$before" "$(md5sum <"$MENU_FILE")"
assert_file_exists "$FONT"

finish
