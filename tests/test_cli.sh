#!/usr/bin/env bash
#
# CLI surface — help, version, list, status and argument handling.

source "$(dirname "${BASH_SOURCE[0]}")/helpers/env.sh"

# ---------------------------------------------------------------------------
echo "cli: help and version"
# ---------------------------------------------------------------------------

test_case "help exits zero and lists every command"
reset_state
run_cli help
assert_status 0 "$STATUS"
for cmd in install remove default status list menu doctor version help; do
  assert_contains "$OUT" "  $cmd" "help should document '$cmd'"
done

test_case "no arguments prints help"
run_cli
assert_status 0 "$STATUS"
assert_contains "$OUT" "USAGE"

test_case "-h and --help are equivalents"
run_cli -h
assert_contains "$OUT" "USAGE"
run_cli --help
assert_status 0 "$STATUS"
assert_contains "$OUT" "BROWSERS"

test_case "help lists the managed browsers"
assert_contains "$OUT" "helium librewolf waterfox vivaldi floorp"

test_case "version prints the tool and Omarchy versions"
run_cli version
assert_status 0 "$STATUS"
assert_contains "$OUT" "omarchy-browsers 1.0.0"
assert_contains "$OUT" "omarchy: 4.0.6-1"
assert_contains "$OUT" "browsers: helium"

test_case "-V and --version map to version"
run_cli -V
assert_status 0 "$STATUS"
assert_contains "$OUT" "omarchy-browsers"
run_cli --version
assert_status 0 "$STATUS"
assert_contains "$OUT" "omarchy-browsers"

test_case "an unknown command exits 2"
reset_state
run_cli frobnicate
assert_status 2 "$STATUS"
assert_contains "$OUT" "unknown command: frobnicate"
assert_contains "$OUT" "Run 'omarchy-browsers help' for usage."

# ---------------------------------------------------------------------------
echo "cli: list"
# ---------------------------------------------------------------------------

test_case "list shows the registry"
reset_state
run_cli list
assert_status 0 "$STATUS"
assert_contains "$OUT" "NAME"
assert_contains "$OUT" "DISPLAY"
assert_contains "$OUT" "SOURCE"
assert_contains "$OUT" "PACKAGES"
for name in helium librewolf waterfox vivaldi floorp; do
  assert_contains "$OUT" "$name"
done

test_case "list marks AUR browsers"
assert_contains "$OUT" "aur"
assert_contains "$OUT" "helium-browser-bin"

test_case "ls is an alias for list"
run_cli ls
assert_status 0 "$STATUS"
assert_contains "$OUT" "helium-browser-bin"

# ---------------------------------------------------------------------------
echo "cli: status"
# ---------------------------------------------------------------------------

test_case "status shows every browser"
reset_state
run_cli status
assert_status 0 "$STATUS"
for name in helium librewolf waterfox vivaldi floorp; do
  assert_contains "$OUT" "$name"
done

test_case "status reports the default browser"
set_default_desktop helium.desktop
run_cli status
assert_contains "$OUT" "Default browser: helium.desktop"

test_case "status warns when no default is set"
rm -f "$TEST_STATE/default.desktop"
run_cli status
assert_contains "$OUT" "No default browser is set."

test_case "status marks the installed and default browser"
reset_state
fake_package helium-browser-bin
fake_desktop helium.desktop helium-browser
set_default_desktop helium.desktop
run_cli status
helium_line=$(printf '%s\n' "$OUT" | grep '^helium ')
assert_contains "$helium_line" "yes" "installed column"
assert_contains "$helium_line" "✓" "default column"
assert_contains "$helium_line" "helium.desktop"

test_case "status --json is valid JSON"
reset_state
run_cli status --json
assert_status 0 "$STATUS"
if command -v node >/dev/null 2>&1; then
  printf '%s' "$OUT" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const j=JSON.parse(s);if(j.browsers.length!==5)process.exit(1)})'
  assert_status 0 "$?" "node rejected the JSON"
else
  printf '%s' "$OUT" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert len(d["browsers"])==5'
  assert_status 0 "$?" "python rejected the JSON"
fi

test_case "status --json reports schema and default"
assert_contains "$OUT" '"schema": 1'
assert_contains "$OUT" '"omarchy_version": "4.0.6-1"'

test_case "status --json escapes the desktop path"
reset_state
fake_package helium-browser-bin
fake_desktop helium.desktop helium-browser
run_cli status --json
assert_contains "$OUT" '"desktop": "helium.desktop"'
assert_contains "$OUT" '"installed": true'

test_case "status rejects unknown options"
run_cli status --yaml
assert_status 2 "$STATUS"
assert_contains "$OUT" "unknown option for status"

# ---------------------------------------------------------------------------
echo "cli: options"
# ---------------------------------------------------------------------------

test_case "--no-color strips ANSI escapes"
reset_state
run_cli --no-color status
assert_status 0 "$STATUS"
assert_not_contains "$OUT" $'\033['

test_case "--dry-run is accepted before or after the command"
reset_state
run_cli --dry-run default helium
assert_contains "$OUT" "[dry-run]"
run_cli default helium --dry-run
assert_status 0 "$STATUS"
assert_contains "$OUT" "[dry-run]"

finish
