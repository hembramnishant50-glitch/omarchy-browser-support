#!/usr/bin/env bash
#
# Remove path — package removal, profile purge, and handing the default over.

source "$(dirname "${BASH_SOURCE[0]}")/helpers/env.sh"

drop_log() { awk '{printf "%s%s", sep, $0; sep=" "}' "$TEST_STATE/pkg-drop.log" 2>/dev/null || true; }
current() { cat "$TEST_STATE/default.desktop" 2>/dev/null || true; }

# ---------------------------------------------------------------------------
echo "remove: packages"
# ---------------------------------------------------------------------------

test_case "removing a browser that is not installed is a no-op"
reset_state
run_cli remove helium
assert_status 0 "$STATUS"
assert_contains "$OUT" "not installed — nothing to remove"
assert_eq "" "$(drop_log)"

test_case "removing an installed browser drops its package"
reset_state
fake_package helium-browser-bin
run_cli remove helium
assert_status 0 "$STATUS"
assert_eq "helium-browser-bin" "$(drop_log)"
assert_file_missing "$TEST_STATE/installed/helium-browser-bin"
assert_contains "$OUT" "Helium removed"

test_case "removing vivaldi drops both packages"
reset_state
fake_package vivaldi
fake_package vivaldi-ffmpeg-codecs
run_cli remove vivaldi
assert_eq "vivaldi vivaldi-ffmpeg-codecs" "$(drop_log)"

test_case "a partial vivaldi install still counts as installed"
reset_state
fake_package vivaldi
run_cli remove vivaldi
assert_status 0 "$STATUS"
assert_eq "vivaldi vivaldi-ffmpeg-codecs" "$(drop_log)"

# ---------------------------------------------------------------------------
echo "remove: purge"
# ---------------------------------------------------------------------------

test_case "--purge wipes the profile even when the package is gone"
reset_state
mkdir -p "$HOME/.config/helium" "$HOME/.cache/helium"
run_cli remove helium --purge
assert_status 0 "$STATUS"
assert_contains "$OUT" "leftover profile data purged"
assert_file_missing "$HOME/.config/helium"
assert_file_missing "$HOME/.cache/helium"

test_case "--purge keeps the profile when no flag is passed"
reset_state
mkdir -p "$HOME/.config/helium"
run_cli remove helium
[[ -d $HOME/.config/helium ]] || fail "profile was removed without --purge"

test_case "--purge after a real removal wipes profile and cache"
reset_state
fake_package helium-browser-bin
mkdir -p "$HOME/.config/helium" "$HOME/.local/share/helium" "$HOME/.cache/helium"
run_cli remove helium --purge
assert_status 0 "$STATUS"
assert_contains "$OUT" "Profile data purged"
assert_file_missing "$HOME/.config/helium"
assert_file_missing "$HOME/.local/share/helium"
assert_file_missing "$HOME/.cache/helium"

test_case "--purge leaves other browsers' profiles alone"
reset_state
mkdir -p "$HOME/.config/helium" "$HOME/.config/vivaldi"
fake_package helium-browser-bin
run_cli remove helium --purge
assert_file_missing "$HOME/.config/helium"
[[ -d $HOME/.config/vivaldi ]] || fail "purge touched an unrelated profile"

# ---------------------------------------------------------------------------
echo "remove: default browser handover"
# ---------------------------------------------------------------------------

test_case "removing the default hands it to an installed stock browser"
reset_state
fake_package helium-browser-bin
fake_desktop helium.desktop helium-browser
fake_command firefox
set_default_desktop helium.desktop
run_cli remove helium
assert_status 0 "$STATUS"
assert_contains "$OUT" "switching the default to Firefox"
assert_eq "firefox.desktop" "$(current)"
assert_contains "$(cat "$TEST_STATE/notify.log" 2>/dev/null)" "Firefox is now the default browser"

test_case "handover prefers another managed browser when no stock one is installed"
reset_state
fake_package helium-browser-bin
fake_package librewolf
fake_desktop helium.desktop helium-browser
fake_desktop librewolf.desktop librewolf
set_default_desktop helium.desktop
run_cli remove helium
assert_status 0 "$STATUS"
assert_eq "librewolf.desktop" "$(current)"

test_case "no survivor means a warning, not a failure"
reset_state
fake_package helium-browser-bin
fake_desktop helium.desktop helium-browser
set_default_desktop helium.desktop
run_cli remove helium
assert_status 0 "$STATUS"
assert_contains "$OUT" "no other browser is installed"
assert_contains "$OUT" "Helium removed"

test_case "removing a non-default browser leaves the default alone"
reset_state
fake_package helium-browser-bin
fake_package librewolf
fake_desktop helium.desktop helium-browser
fake_desktop librewolf.desktop librewolf
set_default_desktop librewolf.desktop
run_cli remove helium
assert_eq "librewolf.desktop" "$(current)"

# ---------------------------------------------------------------------------
echo "remove: multiple, errors and dry-run"
# ---------------------------------------------------------------------------

test_case "several browsers in one call"
reset_state
fake_package helium-browser-bin
fake_package librewolf
run_cli remove helium librewolf
assert_status 0 "$STATUS"
assert_eq "helium-browser-bin librewolf" "$(drop_log)"

test_case "'all' processes every managed browser"
reset_state
run_cli remove all
assert_status 0 "$STATUS"
assert_contains "$OUT" "5 browser(s) processed"

test_case "an unknown browser is rejected"
run_cli remove netscape
assert_status 1 "$STATUS"
assert_contains "$OUT" "unknown browser 'netscape'"

test_case "remove without arguments is a usage error"
run_cli remove
assert_status 2 "$STATUS"

test_case "unknown remove options are rejected"
run_cli remove helium --keep-profile
assert_status 2 "$STATUS"

test_case "--dry-run does not drop the package"
reset_state
fake_package helium-browser-bin
run_cli --dry-run remove helium
assert_status 0 "$STATUS"
assert_contains "$OUT" "[dry-run]"
assert_eq "" "$(drop_log)"
assert_file_exists "$TEST_STATE/installed/helium-browser-bin"

test_case "--dry-run does not purge the profile"
reset_state
mkdir -p "$HOME/.config/helium"
run_cli --dry-run remove helium --purge
[[ -d $HOME/.config/helium ]] || fail "dry-run purged the profile"

finish
