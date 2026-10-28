#!/usr/bin/env bash
#
# Shared test sandbox.
#
# Every test gets a throwaway HOME, config/data dirs and a bin dir full of
# stubs for Omarchy's helpers, so the suite can exercise install/remove/menu
# without touching a real system or requiring Omarchy at all.
#
# shellcheck shell=bash

set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
export ROOT

TEST_TMP="$(mktemp -d "${TMPDIR:-/tmp}/obs-test.XXXXXX")"
export TEST_TMP
export TEST_STATE="$TEST_TMP/state"
mkdir -p "$TEST_STATE/installed" "$TEST_STATE/commands" \
  "$TEST_TMP/bin" "$TEST_TMP/home" "$TEST_TMP/config" "$TEST_TMP/data" \
  "$TEST_TMP/data-dirs"

# Menu validation shells out to node when available; keep the real one on the
# sandbox PATH so the suite exercises that path instead of skipping it.
REAL_NODE=$(command -v node 2>/dev/null || true)

export HOME="$TEST_TMP/home"
export XDG_CONFIG_HOME="$TEST_TMP/config"
export XDG_DATA_HOME="$TEST_TMP/data"
export XDG_DATA_DIRS="$TEST_TMP/data-dirs"
export PATH="$TEST_TMP/bin:$ROOT/bin:/usr/local/bin:/usr/bin:/bin"
export NO_COLOR=1
unset DRY_RUN || true

[[ -n $REAL_NODE ]] && ln -sf "$REAL_NODE" "$TEST_TMP/bin/node"

# A hermetic Omarchy tree: the menu file merge target and the menu model that
# lib/menu.sh validates against, copied from tests/fixtures.
export OMARCHY_PATH="$TEST_TMP/omarchy"
mkdir -p "$OMARCHY_PATH"
cp -R "$ROOT/tests/fixtures/omarchy/." "$OMARCHY_PATH/"

cleanup() { rm -rf "$TEST_TMP"; }
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Omarchy stubs
# ---------------------------------------------------------------------------

cat >"$TEST_TMP/bin/omarchy" <<'STUB'
#!/usr/bin/env bash
state=$TEST_STATE
case "${1:-}" in
pkg)
  case "${2:-}" in
  add)
    shift 2
    printf '%s\n' "$*" >>"$state/pkg-add.log"
    for p in "$@"; do : >"$state/installed/$p"; done
    ;;
  drop)
    shift 2
    printf '%s\n' "$*" >>"$state/pkg-drop.log"
    for p in "$@"; do rm -f "$state/installed/$p"; done
    ;;
  aur)
    case "${3:-}" in
    add)
      shift 3
      printf '%s\n' "$*" >>"$state/aur-add.log"
      for p in "$@"; do : >"$state/installed/$p"; done
      ;;
    accessible) exit "${AUR_ACCESSIBLE:-0}" ;;
    esac
    ;;
  esac
  ;;
version) printf '4.0.6-1\n' ;;
esac
STUB

cat >"$TEST_TMP/bin/omarchy-pkg-present" <<'STUB'
#!/usr/bin/env bash
for p in "$@"; do [[ -e "$TEST_STATE/installed/$p" ]] || exit 1; done
STUB

cat >"$TEST_TMP/bin/omarchy-pkg-missing" <<'STUB'
#!/usr/bin/env bash
for p in "$@"; do [[ -e "$TEST_STATE/installed/$p" ]] || exit 0; done
exit 1
STUB

cat >"$TEST_TMP/bin/omarchy-cmd-present" <<'STUB'
#!/usr/bin/env bash
[[ -e "$TEST_STATE/commands/$1" ]]
STUB

cat >"$TEST_TMP/bin/omarchy-cmd-default-browser" <<'STUB'
#!/usr/bin/env bash
cat "$TEST_STATE/default.desktop" 2>/dev/null
exit 0
STUB

cat >"$TEST_TMP/bin/omarchy-notification-send" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$TEST_STATE/notify.log"
STUB

cat >"$TEST_TMP/bin/omarchy-launch-floating-terminal-with-presentation" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$TEST_STATE/launch.log"
STUB

cat >"$TEST_TMP/bin/xdg-settings" <<'STUB'
#!/usr/bin/env bash
case "${1:-}" in
set)
  [[ ${2:-} == default-web-browser ]] || exit 1
  printf '%s\n' "$3" >"$TEST_STATE/default.desktop"
  ;;
get) cat "$TEST_STATE/default.desktop" 2>/dev/null ;;
esac
STUB

cat >"$TEST_TMP/bin/xdg-mime" <<'STUB'
#!/usr/bin/env bash
case "${1:-}" in
default) printf '%s\n' "${2:-}" >"$TEST_STATE/default.desktop" ;;
query) cat "$TEST_STATE/default.desktop" 2>/dev/null ;;
esac
STUB

cat >"$TEST_TMP/bin/fc-cache" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB

# Only used when omarchy's own helpers are absent; harmless in the sandbox.
cat >"$TEST_TMP/bin/pacman" <<'STUB'
#!/usr/bin/env bash
exit 1
STUB

cat >"$TEST_TMP/bin/curl" <<'STUB'
#!/usr/bin/env bash
exit 1
STUB

# Only the stubs are ours; node is a symlink to the real binary, and chmod
# would follow it (and fail) on systems where that file is not owned by us.
find "$TEST_TMP/bin" -maxdepth 1 -type f -exec chmod +x {} +

# ---------------------------------------------------------------------------
# Fixture helpers
# ---------------------------------------------------------------------------

# fake_package <name> — make the stub package manager report it installed.
fake_package() { : >"$TEST_STATE/installed/$1"; }

# fake_command <name> — make omarchy-cmd-present succeed for it.
fake_command() { : >"$TEST_STATE/commands/$1"; }

# fake_desktop <id> <exec> [dir]
fake_desktop() {
  local id=$1 exec=$2 dir=${3:-$XDG_DATA_HOME}
  mkdir -p "$dir/applications"
  {
    printf '[Desktop Entry]\nType=Application\nName=%s\n' "${id%.desktop}"
    printf 'Exec=%s %%U\n' "$exec"
  } >"$dir/applications/$id"
}

set_default_desktop() { printf '%s\n' "$1" >"$TEST_STATE/default.desktop"; }

# reset_state — forget installed packages, commands, default browser and logs.
# Call it at the start of any test that depends on a clean slate.
reset_state() {
  rm -rf "$TEST_STATE/installed" "$TEST_STATE/commands" "$TEST_STATE"/*.log \
    "$TEST_STATE/default.desktop"
  mkdir -p "$TEST_STATE/installed" "$TEST_STATE/commands"
  rm -rf "$XDG_CONFIG_HOME/omarchy" "$XDG_DATA_HOME/fonts" "$XDG_DATA_HOME/applications"
  # install.sh links into $HOME/.local/bin; wipe it so a leftover symlink can
  # never be written through by a later test.
  rm -rf "$HOME/.local"
  # Tests are allowed to break the fake Omarchy tree; restore it each time so
  # one suite's damage never leaks into the next test.
  rm -rf "$OMARCHY_PATH"
  mkdir -p "$OMARCHY_PATH"
  cp -R "$ROOT/tests/fixtures/omarchy/." "$OMARCHY_PATH/"
}

# run_cli <args…> — run the dispatcher and capture stdout+stderr in $OUT.
run_cli() {
  OUT=$("$ROOT/bin/omarchy-browsers" "$@" 2>&1)
  # shellcheck disable=SC2034 # read by the calling test
  STATUS=$?
}

# run_lib <code> — run bash code with lib/core.sh + lib/menu.sh sourced.
run_lib() {
  # shellcheck disable=SC2034 # read by the calling test
  OUT=$(bash -c 'source "$1/lib/core.sh"; source "$1/lib/menu.sh"; eval "$2"' \
    _ "$ROOT" "$1" 2>&1)
  # shellcheck disable=SC2034 # read by the calling test
  STATUS=$?
}

# ---------------------------------------------------------------------------
# Assertions
# ---------------------------------------------------------------------------

TESTS_RUN=0
TESTS_FAILED=0
CURRENT_TEST=''

test_case() { CURRENT_TEST=$1; TESTS_RUN=$((TESTS_RUN + 1)); }

fail() {
  TESTS_FAILED=$((TESTS_FAILED + 1))
  printf '  FAIL [%s] %s\n' "$CURRENT_TEST" "$*"
}

assert_eq() {
  local expected=$1 actual=$2 msg=${3:-values differ}
  [[ $expected == "$actual" ]] || fail "$msg (expected '$expected', got '$actual')"
}

assert_contains() {
  local haystack=$1 needle=$2 msg=${3:-substring not found}
  [[ $haystack == *"$needle"* ]] || fail "$msg (looked for '$needle' in '$haystack')"
}

assert_not_contains() {
  local haystack=$1 needle=$2 msg=${3:-unexpected substring}
  [[ $haystack != *"$needle"* ]] || fail "$msg (found '$needle' in '$haystack')"
}

assert_status() {
  local expected=$1 actual=$2 msg=${3:-status mismatch}
  [[ $expected == "$actual" ]] || fail "$msg (expected $expected, got $actual)"
}

assert_file_exists() {
  [[ -f $1 ]] || fail "expected file to exist: $1"
}

assert_file_missing() {
  [[ ! -e $1 ]] || fail "expected path to be gone: $1"
}

finish() {
  printf '%s: %d checks, %d failed\n' \
    "$(basename "$0")" "$TESTS_RUN" "$TESTS_FAILED"
  (( TESTS_FAILED == 0 ))
}
