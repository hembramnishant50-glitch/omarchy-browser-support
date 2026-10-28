#!/usr/bin/env bash
#
# install.sh / uninstall.sh — the symlink contract and menu hand-off.
#
# These scripts are what a new user runs first, so they must be safe to run
# twice and must never delete a file they did not create.

source "$(dirname "${BASH_SOURCE[0]}")/helpers/env.sh"

LINK="$HOME/.local/bin/omarchy-browsers"
MENU_FILE="$XDG_CONFIG_HOME/omarchy/extensions/omarchy-menu.jsonc"

run_installer() { OUT=$("$ROOT/install.sh" "$@" 2>&1); STATUS=$?; }
run_uninstaller() { OUT=$("$ROOT/uninstall.sh" "$@" 2>&1); STATUS=$?; }

# ---------------------------------------------------------------------------
echo "installer: symlink"
# ---------------------------------------------------------------------------

test_case "install.sh links the dispatcher into ~/.local/bin"
reset_state
run_installer --no-menu
assert_status 0 "$STATUS"
[[ -L $LINK ]] || fail "expected a symlink at $LINK"
assert_eq "$ROOT/bin/omarchy-browsers" "$(readlink -f -- "$LINK")"
assert_contains "$OUT" "linked."

test_case "the linked command runs"
OUT=$("$LINK" version 2>&1)
STATUS=$?
assert_status 0 "$STATUS"
assert_contains "$OUT" "omarchy-browsers 1.0.0"

test_case "a second install is idempotent"
run_installer --no-menu
assert_status 0 "$STATUS"
assert_contains "$OUT" "already linked."
[[ -L $LINK ]] || fail "the symlink disappeared"

test_case "install refuses to clobber a real file"
reset_state
mkdir -p "$HOME/.local/bin"
rm -f "$LINK"
printf '#!/bin/sh\n' >"$LINK"
run_installer --no-menu
assert_status 1 "$STATUS"
assert_contains "$OUT" "already exists and is not a symlink"
assert_eq "#!/bin/sh" "$(cat "$LINK")"

test_case "--bin-dir puts the link elsewhere"
reset_state
run_installer --no-menu --bin-dir "$TEST_TMP/custom-bin"
assert_status 0 "$STATUS"
[[ -L $TEST_TMP/custom-bin/omarchy-browsers ]] || fail "custom bin dir was ignored"

test_case "--dry-run creates nothing"
reset_state
run_installer --dry-run --no-menu
assert_status 0 "$STATUS"
assert_contains "$OUT" "[dry-run]"
[[ ! -e $LINK ]] || fail "dry-run created the symlink"

# ---------------------------------------------------------------------------
echo "installer: menu hand-off"
# ---------------------------------------------------------------------------

test_case "install runs menu setup by default"
reset_state
run_installer
assert_status 0 "$STATUS"
assert_file_exists "$MENU_FILE"
assert_contains "$OUT" "15 menu rows ready"

test_case "--no-menu skips the menu"
reset_state
run_installer --no-menu
assert_status 0 "$STATUS"
assert_file_missing "$MENU_FILE"
assert_contains "$OUT" "Skipped the menu"

test_case "install --dry-run does not write the menu"
reset_state
run_installer --dry-run
assert_status 0 "$STATUS"
assert_file_missing "$MENU_FILE"

# ---------------------------------------------------------------------------
echo "uninstaller"
# ---------------------------------------------------------------------------

test_case "uninstall removes its own link and the menu rows"
reset_state
run_installer
run_uninstaller
assert_status 0 "$STATUS"
[[ ! -e $LINK ]] || fail "the symlink was left behind"
assert_contains "$(cat "$MENU_FILE")" "{"
assert_not_contains "$(cat "$MENU_FILE")" "omarchy-browser-support"
assert_contains "$OUT" "not touched"

test_case "uninstall leaves a foreign link alone"
reset_state
mkdir -p "$HOME/.local/bin"
ln -s /bin/true "$LINK"
run_uninstaller --keep-menu
assert_status 0 "$STATUS"
assert_contains "$OUT" "left alone"
[[ -L $LINK ]] || fail "uninstall removed a link it did not create"

test_case "uninstall without an install is harmless"
reset_state
run_uninstaller
assert_status 0 "$STATUS"
assert_contains "$OUT" "nothing to remove"

test_case "--keep-menu preserves the integration"
reset_state
run_installer
run_uninstaller --keep-menu
assert_file_exists "$MENU_FILE"
assert_contains "$(cat "$MENU_FILE")" "omarchy-browser-support"

test_case "an unknown option is rejected"
run_uninstaller --force
assert_status 2 "$STATUS"
assert_contains "$OUT" "unknown option"

finish
