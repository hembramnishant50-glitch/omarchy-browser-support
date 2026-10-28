#!/usr/bin/env bash
#
# Default browser — setting, reading, the menu's --check hook, and dry-run.

source "$(dirname "${BASH_SOURCE[0]}")/helpers/env.sh"

current() { cat "$TEST_STATE/default.desktop" 2>/dev/null || true; }

# ---------------------------------------------------------------------------
echo "default: reading"
# ---------------------------------------------------------------------------

test_case "prints the current default"
reset_state
set_default_desktop helium.desktop
run_cli default
assert_status 0 "$STATUS"
assert_eq "helium.desktop" "$OUT"

test_case "prints 'none' when nothing is set"
reset_state
rm -f "$TEST_STATE/default.desktop"
run_cli default
assert_status 0 "$STATUS"
assert_eq "none" "$OUT"

test_case "the omarchy redirect stub reads as 'none'"
reset_state
printf 'omarchy-browser.desktop\n' >"$TEST_STATE/default.desktop"
run_cli default
assert_eq "none" "$OUT"

# ---------------------------------------------------------------------------
echo "default: setting"
# ---------------------------------------------------------------------------

test_case "sets a managed browser as default"
reset_state
fake_desktop helium.desktop helium-browser
run_cli default helium
assert_status 0 "$STATUS"
assert_eq "helium.desktop" "$(current)"
assert_contains "$OUT" "Helium is now the default browser"

test_case "notifies with the browser's own glyph"
assert_contains "$(cat "$TEST_STATE/notify.log")" "󰊠 Helium is now the default browser"

test_case "sets a stock browser without a .desktop file present"
reset_state
run_cli default firefox
assert_status 0 "$STATUS"
assert_eq "firefox.desktop" "$(current)"

test_case "an uninstalled managed browser cannot become default"
reset_state
run_cli default helium
assert_status 1 "$STATUS"
assert_contains "$OUT" "Helium is not installed (no .desktop entry found)"

test_case "an unknown browser is rejected"
reset_state
run_cli default netscape
assert_status 1 "$STATUS"
assert_contains "$OUT" "unknown browser 'netscape'"
assert_contains "$OUT" "chromium"

test_case "two browser names are a usage error"
run_cli default helium librewolf
assert_status 2 "$STATUS"
assert_contains "$OUT" "default takes one browser"

# ---------------------------------------------------------------------------
echo "default: --check hook"
# ---------------------------------------------------------------------------

test_case "--check succeeds for the active default"
reset_state
fake_desktop helium.desktop helium-browser
set_default_desktop helium.desktop
run_cli default helium --check
assert_status 0 "$STATUS"
assert_eq "" "$OUT" "the menu hook must be silent"

test_case "--check fails for a different default"
set_default_desktop firefox.desktop
run_cli default helium --check
assert_status 1 "$STATUS"

test_case "--check works for stock browsers"
run_cli default firefox --check
assert_status 0 "$STATUS"

test_case "--check without a browser is a usage error"
run_cli default --check
assert_status 2 "$STATUS"

# ---------------------------------------------------------------------------
echo "default: dry-run"
# ---------------------------------------------------------------------------

test_case "--dry-run prints the command and changes nothing"
reset_state
fake_desktop helium.desktop helium-browser
set_default_desktop firefox.desktop
run_cli --dry-run default helium
assert_status 0 "$STATUS"
assert_contains "$OUT" "[dry-run]"
assert_contains "$OUT" "xdg-settings set default-web-browser helium.desktop"
assert_eq "firefox.desktop" "$(current)"

test_case "--dry-run does not notify"
[[ ! -f $TEST_STATE/notify.log ]] || fail "dry-run sent a notification"

finish
