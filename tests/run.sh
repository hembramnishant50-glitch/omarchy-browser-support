#!/usr/bin/env bash
#
# Test runner — discovers tests/test_*.sh and runs each in its own process.
#
#   tests/run.sh                 run everything
#   tests/run.sh menu registry   only files matching a pattern
#   tests/run.sh --verbose       stream each suite's output
#   tests/run.sh --list          show the suites and exit
#
# Each suite is self-contained: it builds a throwaway HOME and a fake Omarchy
# tree, so the runner never touches the real system.

set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export ROOT

VERBOSE=0
LIST_ONLY=0
FILTERS=()

for arg in "$@"; do
  case $arg in
  -v | --verbose) VERBOSE=1 ;;
  -l | --list) LIST_ONLY=1 ;;
  -h | --help)
    sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
  -*)
    printf 'unknown option: %s\n' "$arg" >&2
    exit 2
    ;;
  *) FILTERS+=("$arg") ;;
  esac
done

shopt -s nullglob
SUITES=("$ROOT"/tests/test_*.sh)
shopt -u nullglob

if (( ${#SUITES[@]} == 0 )); then
  printf 'no test suites found under %s/tests\n' "$ROOT" >&2
  exit 1
fi

# Apply the optional name filters.
selected=()
for suite in "${SUITES[@]}"; do
  base=$(basename "$suite" .sh)
  if (( ${#FILTERS[@]} == 0 )); then
    selected+=("$suite")
    continue
  fi
  for f in "${FILTERS[@]}"; do
    if [[ $base == *"$f"* ]]; then
      selected+=("$suite")
      break
    fi
  done
done

if (( ${#selected[@]} == 0 )); then
  printf 'no suite matched: %s\n' "${FILTERS[*]}" >&2
  exit 1
fi

if (( LIST_ONLY )); then
  for suite in "${selected[@]}"; do basename "$suite" .sh; done
  exit 0
fi

# ---------------------------------------------------------------------------

BOLD='' DIM='' GREEN='' RED='' RESET=''
if [[ -t 1 && -z ${NO_COLOR:-} ]]; then
  BOLD=$'\033[1m' DIM=$'\033[2m' GREEN=$'\033[32m' RED=$'\033[31m' RESET=$'\033[0m'
fi

total_suites=0
failed_suites=0
total_checks=0
total_failed=0
failed_names=()

started=$SECONDS

for suite in "${selected[@]}"; do
  name=$(basename "$suite" .sh)
  total_suites=$((total_suites + 1))
  printf '%s▶ %s%s\n' "$BOLD" "$name" "$RESET"

  log=$(mktemp "${TMPDIR:-/tmp}/obs-suite.XXXXXX")
  bash "$suite" >"$log" 2>&1
  rc=$?

  if (( VERBOSE )); then
    sed 's/^/  /' "$log"
  elif (( rc != 0 )); then
    sed 's/^/  /' "$log"
  else
    # Keep only the summary line on success.
    grep -E 'checks?, [0-9]+ failed' "$log" | sed 's/^/  /'
  fi

  checks=$(grep -oE '[0-9]+ checks' "$log" | tail -1 | grep -oE '^[0-9]+' || true)
  bad=$(grep -oE '[0-9]+ failed' "$log" | tail -1 | grep -oE '^[0-9]+' || true)
  total_checks=$((total_checks + ${checks:-0}))
  total_failed=$((total_failed + ${bad:-0}))
  rm -f "$log"

  if (( rc != 0 )); then
    failed_suites=$((failed_suites + 1))
    failed_names+=("$name")
    printf '  %s✗ %s failed%s\n' "$RED" "$name" "$RESET"
  else
    printf '  %s✓ %s passed%s\n' "$GREEN" "$name" "$RESET"
  fi
done

elapsed=$((SECONDS - started))

printf '\n%s%d suite(s), %d check(s), %d failure(s) in %ds%s\n' \
  "$BOLD" "$total_suites" "$total_checks" "$total_failed" "$elapsed" "$RESET"

if (( failed_suites > 0 )); then
  printf '%sfailed: %s%s\n' "$RED" "${failed_names[*]}" "$RESET"
  printf '%srerun with: tests/run.sh %s%s\n' "$DIM" "${failed_names[*]}" "$RESET"
  exit 1
fi

printf '%sall suites passed%s\n' "$GREEN" "$RESET"
