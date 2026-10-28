#!/usr/bin/env bash
#
# .desktop detection — every browser package names its entry differently, and
# some rename it between releases, so detection must be resilient.

source "$(dirname "${BASH_SOURCE[0]}")/helpers/env.sh"

# ---------------------------------------------------------------------------
echo "detect: declared ids"
# ---------------------------------------------------------------------------

test_case "finds the declared desktop id"
reset_state
fake_desktop helium.desktop helium-browser
run_lib 'detect_desktop helium'
assert_status 0 "$STATUS"
assert_eq "helium.desktop" "$OUT"

test_case "prefers the first declared id"
fake_desktop vivaldi.desktop vivaldi
fake_desktop vivaldi-stable.desktop vivaldi
run_lib 'detect_desktop vivaldi'
assert_eq "vivaldi-stable.desktop" "$OUT"

test_case "returns non-zero when nothing is installed"
reset_state
run_lib 'detect_desktop helium'
assert_status 1 "$STATUS"
assert_eq "" "$OUT"

# ---------------------------------------------------------------------------
echo "detect: Exec fallback"
# ---------------------------------------------------------------------------

test_case "matches a renamed entry by Exec="
reset_state
fake_desktop helium-browser-custom.desktop helium-browser
run_lib 'detect_desktop helium'
assert_status 0 "$STATUS"
assert_eq "helium-browser-custom.desktop" "$OUT"

test_case "ignores an Exec that points at a different command"
fake_desktop chromium.desktop chromium
run_lib 'detect_desktop helium'
assert_eq "helium-browser-custom.desktop" "$OUT" "must skip unrelated entries"

test_case "handles a quoted absolute Exec path"
reset_state
fake_desktop waterfox.desktop '"/opt/waterfox/waterfox" %u'
run_lib 'desktop_exec_command "'"$XDG_DATA_HOME"'/applications/waterfox.desktop"'
assert_eq "waterfox" "$OUT"

# ---------------------------------------------------------------------------
echo "detect: XDG search path"
# ---------------------------------------------------------------------------

test_case "searches XDG_DATA_DIRS as well as XDG_DATA_HOME"
reset_state
fake_desktop floorp.desktop floorp "$XDG_DATA_DIRS"
run_lib 'detect_desktop floorp'
assert_status 0 "$STATUS"
assert_eq "floorp.desktop" "$OUT"

test_case "desktop_data_dirs yields every configured directory"
run_lib 'desktop_data_dirs | tr "\n" " "'
assert_eq "$XDG_DATA_HOME $XDG_DATA_DIRS " "$OUT"

# ---------------------------------------------------------------------------
echo "detect: default browser resolution"
# ---------------------------------------------------------------------------

test_case "check_default is true for the active handler"
reset_state
fake_desktop helium.desktop helium-browser
set_default_desktop helium.desktop
run_lib 'check_default helium && echo yes'
assert_eq "yes" "$OUT"

test_case "check_default is false for another handler"
set_default_desktop firefox.desktop
run_lib 'check_default helium && echo yes'
assert_eq "" "$OUT"

test_case "omarchy-browser.desktop is never treated as a browser"
reset_state
fake_desktop helium.desktop helium-browser
printf 'omarchy-browser.desktop\n' >"$TEST_STATE/default.desktop"
run_lib 'printf "[%s]\n" "$(current_default_desktop)"'
assert_eq "[]" "$OUT" "the redirect stub must be ignored"

test_case "stock browsers resolve without a .desktop file"
set_default_desktop firefox.desktop
run_lib 'check_default firefox && echo yes; check_default helium && echo helium'
assert_eq "yes" "$OUT"

test_case "a stock browser with a missing command still resolves for display"
run_lib 'printf "%s:%s\n" "$(browser_label zen)" "$(browser_command zen)"'
assert_eq "Zen:zen-browser" "$OUT"

test_case "purge paths expand relative to HOME"
mkdir -p "$HOME/.config/helium"
run_lib "purge_browser_paths helium"
assert_file_missing "$HOME/.config/helium"

finish
