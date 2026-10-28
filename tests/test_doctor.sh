#!/usr/bin/env bash
#
# doctor — the diagnostic command users run when something looks wrong.

source "$(dirname "${BASH_SOURCE[0]}")/helpers/env.sh"

# ---------------------------------------------------------------------------
echo "doctor: healthy sandbox"
# ---------------------------------------------------------------------------

test_case "doctor succeeds on a clean install"
reset_state
run_cli doctor
assert_status 0 "$STATUS"
assert_contains "$OUT" "Environment"
assert_contains "$OUT" "Registry"
assert_contains "$OUT" "Menu integration"
assert_contains "$OUT" "Browsers"
assert_contains "$OUT" "all checks passed"

test_case "doctor reports the registry contents"
assert_contains "$OUT" "5 browsers: helium librewolf waterfox vivaldi floorp"

test_case "doctor warns before menu setup"
assert_contains "$OUT" "menu file does not exist yet"

test_case "doctor confirms the menu after setup"
reset_state
run_cli menu setup
run_cli doctor
assert_status 0 "$STATUS"
assert_contains "$OUT" "managed block present"
assert_contains "$OUT" "icon font installed: OmarchyHeliumIcon"
assert_contains "$OUT" "menu file parses and merges cleanly"

# ---------------------------------------------------------------------------
echo "doctor: failures"
# ---------------------------------------------------------------------------

test_case "a missing Omarchy tree is a failure"
reset_state
OUT=$(OMARCHY_PATH="$TEST_TMP/nowhere" "$ROOT/bin/omarchy-browsers" doctor 2>&1)
STATUS=$?
assert_status 1 "$STATUS"
assert_contains "$OUT" "Omarchy not found"
assert_contains "$OUT" "failure"

test_case "living under the Omarchy tree is a failure"
reset_state
mkdir -p "$OMARCHY_PATH/support"
cp -R "$ROOT/lib" "$OMARCHY_PATH/support/lib"
OUT=$(OMARCHY_BROWSERS_ROOT="$OMARCHY_PATH/support" "$ROOT/bin/omarchy-browsers" doctor 2>&1)
STATUS=$?
assert_status 1 "$STATUS"
assert_contains "$OUT" "must not live under"

test_case "a missing menu model is a failure"
reset_state
rm -f "$OMARCHY_PATH/shell/plugins/menu/MenuModel.js"
run_cli doctor
assert_status 1 "$STATUS"
assert_contains "$OUT" "menu model missing"

# ---------------------------------------------------------------------------
echo "doctor: warnings only"
# ---------------------------------------------------------------------------

test_case "no default browser is only a warning"
reset_state
rm -f "$TEST_STATE/default.desktop"
run_cli doctor
assert_status 0 "$STATUS"
assert_contains "$OUT" "no default browser is set"

test_case "a default pointing at a missing command warns"
reset_state
fake_desktop helium.desktop helium-browser
set_default_desktop helium.desktop
run_cli doctor
assert_status 0 "$STATUS"
assert_contains "$OUT" "points at a missing command: helium-browser"

test_case "a healthy default is reported"
reset_state
fake_desktop helium.desktop helium-browser
fake_command helium-browser
set_default_desktop helium.desktop
run_cli doctor
assert_contains "$OUT" "default browser: helium.desktop (Exec: helium-browser)"

test_case "an installed browser without a desktop entry fails"
reset_state
fake_package helium-browser-bin
run_cli doctor
assert_status 1 "$STATUS"
assert_contains "$OUT" "installed but no .desktop entry found"

test_case "installed browsers are reported with their entry"
reset_state
fake_package helium-browser-bin
fake_desktop helium.desktop helium-browser
fake_command helium-browser
run_cli doctor
assert_status 0 "$STATUS"
assert_contains "$OUT" "Helium: installed, desktop entry helium.desktop"
assert_contains "$OUT" "Helium: command helium-browser resolves"

test_case "a missing optional tool is a warning, not a failure"
reset_state
# Hide node from the sandbox instead of restricting PATH: the sandbox PATH also
# carries the omarchy/pacman stubs, and doctor rightly fails without those.
node_link=''
if [[ -L $TEST_TMP/bin/node ]]; then
  node_link=$(readlink "$TEST_TMP/bin/node")
  rm -f "$TEST_TMP/bin/node"
fi
OUT=$(PATH="$(without_tool node)" "$ROOT/bin/omarchy-browsers" doctor 2>&1)
STATUS=$?
assert_status 0 "$STATUS"
assert_contains "$OUT" "optional command missing: node"
[[ -z $node_link ]] || ln -sf "$node_link" "$TEST_TMP/bin/node"

finish
