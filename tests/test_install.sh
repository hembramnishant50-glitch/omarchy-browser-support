#!/usr/bin/env bash
#
# Install path — packages, AUR routing, idempotency and dry-run.

source "$(dirname "${BASH_SOURCE[0]}")/helpers/env.sh"

pkg_log() { awk '{printf "%s%s", sep, $0; sep=" "}' "$TEST_STATE/pkg-add.log" 2>/dev/null || true; }
aur_log() { awk '{printf "%s%s", sep, $0; sep=" "}' "$TEST_STATE/aur-add.log" 2>/dev/null || true; }

# ---------------------------------------------------------------------------
echo "install: repository packages"
# ---------------------------------------------------------------------------

test_case "install helium pulls the official package"
reset_state
run_cli install helium
assert_status 0 "$STATUS"
assert_contains "$OUT" "Helium installed"
assert_eq "helium-browser-bin" "$(pkg_log)"
assert_eq "" "$(aur_log)" "helium must not go through the AUR"
assert_file_exists "$TEST_STATE/installed/helium-browser-bin"

test_case "installing twice is a no-op"
run_cli install helium
assert_status 0 "$STATUS"
assert_contains "$OUT" "already installed"
assert_eq "helium-browser-bin" "$(pkg_log)" "the package must not be installed twice"

test_case "install reports the desktop entry when present"
reset_state
fake_desktop helium.desktop helium-browser
run_cli install helium
assert_contains "$OUT" "desktop entry: helium.desktop"

test_case "install warns when the desktop entry is missing"
reset_state
run_cli install helium
assert_contains "$OUT" "no .desktop entry found"

test_case "vivaldi installs its ffmpeg codec alongside"
reset_state
run_cli install vivaldi
assert_status 0 "$STATUS"
assert_eq "vivaldi vivaldi-ffmpeg-codecs" "$(pkg_log)"

# ---------------------------------------------------------------------------
echo "install: AUR packages"
# ---------------------------------------------------------------------------

test_case "waterfox is built from the AUR"
reset_state
run_cli install waterfox
assert_status 0 "$STATUS"
assert_eq "waterfox-bin" "$(aur_log)"
assert_eq "" "$(pkg_log)" "AUR packages must not use omarchy pkg add"

test_case "floorp is built from the AUR"
reset_state
run_cli install floorp
assert_eq "floorp-bin" "$(aur_log)"

test_case "install checks AUR availability first"
reset_state
run_cli install floorp
assert_not_contains "$OUT" "AUR availability check failed"

test_case "a failing AUR check only warns"
reset_state
AUR_ACCESSIBLE=1 run_cli install floorp
assert_status 0 "$STATUS" "the install should still be attempted"
assert_contains "$OUT" "AUR availability check failed"
assert_eq "floorp-bin" "$(aur_log)"

# ---------------------------------------------------------------------------
echo "install: multiple browsers"
# ---------------------------------------------------------------------------

test_case "several browsers in one call"
reset_state
run_cli install helium librewolf
assert_status 0 "$STATUS"
assert_eq "helium-browser-bin librewolf" "$(pkg_log)"
assert_contains "$OUT" "2 browser(s) processed"

test_case "'all' installs every managed browser"
reset_state
run_cli install all
assert_status 0 "$STATUS"
assert_contains "$(pkg_log)" "helium-browser-bin"
assert_contains "$(pkg_log)" "vivaldi"
assert_eq "waterfox-bin floorp-bin" "$(aur_log)"

# ---------------------------------------------------------------------------
echo "install: errors and dry-run"
# ---------------------------------------------------------------------------

test_case "an unknown browser is rejected"
reset_state
run_cli install netscape
assert_status 1 "$STATUS"
assert_contains "$OUT" "unknown browser 'netscape'"
assert_contains "$OUT" "helium librewolf waterfox vivaldi floorp"

test_case "install without arguments is a usage error"
run_cli install
assert_status 2 "$STATUS"
assert_contains "$OUT" "install needs at least one browser"

test_case "unknown install options are rejected"
run_cli install helium --force
assert_status 2 "$STATUS"
assert_contains "$OUT" "unknown option for install"

test_case "--dry-run changes nothing"
reset_state
run_cli --dry-run install helium waterfox
assert_status 0 "$STATUS"
assert_contains "$OUT" "[dry-run]"
assert_eq "" "$(pkg_log)"
assert_eq "" "$(aur_log)"
assert_file_missing "$TEST_STATE/installed/helium-browser-bin"

test_case "--dry-run still validates the browser name"
run_cli --dry-run install netscape
assert_status 1 "$STATUS"

finish
