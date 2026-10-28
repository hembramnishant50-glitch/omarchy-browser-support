#!/usr/bin/env bash
#
# Registry contract tests — lib/browsers.tsv is the single source of truth, so
# its shape, decoding and validation matter more than anything else here.

source "$(dirname "${BASH_SOURCE[0]}")/helpers/env.sh"

# ---------------------------------------------------------------------------
echo "registry: content"
# ---------------------------------------------------------------------------

test_case "loads every managed browser"
run_lib 'printf "%s\n" "${BROWSER_NAMES[@]}"'
assert_status 0 "$STATUS" "core.sh must load in the sandbox"
assert_eq "helium
librewolf
waterfox
vivaldi
floorp" "$OUT" "registry order changed"

test_case "helium is the flagship row"
run_lib 'printf "%s|%s|%s|%s|%s\n" "$(browser_display helium)" \
  "$(browser_primary_package helium)" "$(browser_source helium)" \
  "$(browser_command helium)" "$(browser_icon_font helium)"'
assert_eq "Helium|helium-browser-bin|repo|helium-browser|OmarchyHeliumIcon" "$OUT"

test_case "every row is fully populated"
run_lib '
  for n in "${BROWSER_NAMES[@]}"; do
    for v in "$(browser_display "$n")" "${BROWSER_PACKAGES[$n]}" \
      "$(browser_source "$n")" "$(browser_command "$n")" \
      "$(browser_glyph "$n")" "${BROWSER_PURGE[$n]}"; do
      [[ -n $v ]] || echo "empty:$n"
    done
  done'
assert_eq "" "$OUT" "a registry column should never be empty"

test_case "vivaldi ships two packages"
run_lib 'browser_packages vivaldi p; printf "%s\n" "${#p[@]}:${p[1]}"'
assert_eq "2:vivaldi-ffmpeg-codecs" "$OUT"

test_case "desktop candidates are ordered, primary first"
run_lib 'browser_desktops vivaldi d; printf "%s\n" "${d[0]}"'
assert_eq "vivaldi-stable.desktop" "$OUT"

test_case "glyphs decode from U+XXXX"
run_lib 'browser_glyph helium | od -An -tx1 | tr -d " \n"'
assert_eq "f3b08aa0" "$OUT" "helium notification glyph"

test_case "helium menu glyph is the bundled starburst"
run_lib 'browser_menu_glyph helium | od -An -tx1 | tr -d " \n"'
assert_eq "ee808b" "$OUT" "U+E00B"

test_case "only helium needs a bundled icon font"
run_lib 'menu_icon_fonts'
assert_eq "OmarchyHeliumIcon" "$OUT"

test_case "rows without a menu glyph fall back to the notification glyph"
run_lib 'browser_menu_glyph librewolf | od -An -tx1 | tr -d " \n"'
assert_eq "f3b0969f" "$OUT"

test_case "purge paths stay inside HOME"
run_lib 'for p in ${BROWSER_PURGE[helium]}; do case $p in /*|*..*) echo unsafe;; esac; done'
assert_eq "" "$OUT" "purge paths must be relative"

# ---------------------------------------------------------------------------
echo "registry: validation"
# ---------------------------------------------------------------------------

make_registry() { # make_registry <destination> <row…>
  local dest=$1
  shift
  printf '%s\n' "$@" >"$dest"
}

test_case "rejects a row with the wrong field count"
make_registry "$TEST_TMP/bad-fields.tsv" $'helium\tHelium\thelium-browser-bin'
OUT=$(OMARCHY_BROWSERS_REGISTRY="$TEST_TMP/bad-fields.tsv" \
  bash -c 'source "$1/lib/core.sh"' _ "$ROOT" 2>&1)
STATUS=$?
assert_status 1 "$STATUS" "a 3-field row must fail"
assert_contains "$OUT" "expected 10"

test_case "rejects duplicate browser names"
make_registry "$TEST_TMP/dupe.tsv" \
  $'helium\tHelium\thp\trepo\thelium-browser\thelium.desktop\tU+F02A0\t\t\t.x' \
  $'helium\tHelium\thp\trepo\thelium-browser\thelium.desktop\tU+F02A0\t\t\t.x'
OUT=$(OMARCHY_BROWSERS_REGISTRY="$TEST_TMP/dupe.tsv" \
  bash -c 'source "$1/lib/core.sh"' _ "$ROOT" 2>&1)
STATUS=$?
assert_status 1 "$STATUS" "duplicate names must fail"
assert_contains "$OUT" "duplicate browser 'helium'"

test_case "rejects an unknown package source"
make_registry "$TEST_TMP/bad-source.tsv" \
  $'helium\tHelium\thp\tsnap\thelium-browser\thelium.desktop\tU+F02A0\t\t\t.x'
OUT=$(OMARCHY_BROWSERS_REGISTRY="$TEST_TMP/bad-source.tsv" \
  bash -c 'source "$1/lib/core.sh"' _ "$ROOT" 2>&1)
assert_status 1 "$STATUS"
assert_contains "$OUT" "source must be"

test_case "rejects an absolute purge path"
make_registry "$TEST_TMP/bad-purge.tsv" \
  $'helium\tHelium\thp\trepo\thelium-browser\thelium.desktop\tU+F02A0\t\t\t/etc'
OUT=$(OMARCHY_BROWSERS_REGISTRY="$TEST_TMP/bad-purge.tsv" \
  bash -c 'source "$1/lib/core.sh"' _ "$ROOT" 2>&1)
assert_status 1 "$STATUS"
assert_contains "$OUT" "unsafe purge path"

test_case "rejects a browser name with uppercase letters"
make_registry "$TEST_TMP/bad-name.tsv" \
  $'Helium\tHelium\thp\trepo\thelium-browser\thelium.desktop\tU+F02A0\t\t\t.x'
OUT=$(OMARCHY_BROWSERS_REGISTRY="$TEST_TMP/bad-name.tsv" \
  bash -c 'source "$1/lib/core.sh"' _ "$ROOT" 2>&1)
assert_status 1 "$STATUS"
assert_contains "$OUT" "bad browser name"

test_case "split_tsv preserves empty fields"
run_lib 'split_tsv "$(printf "a\t\tc\td")"; printf "%s:%s\n" "${#SPLIT_FIELDS[@]}" "${SPLIT_FIELDS[1]:-EMPTY}"'
assert_eq "4:EMPTY" "$OUT"

test_case "comments and blank lines are ignored"
cp "$ROOT/lib/browsers.tsv" "$TEST_TMP/comments.tsv"
printf '\n# just a comment\n\n' >>"$TEST_TMP/comments.tsv"
OUT=$(OMARCHY_BROWSERS_REGISTRY="$TEST_TMP/comments.tsv" \
  bash -c 'source "$1/lib/core.sh"; printf "%s\n" "${#BROWSER_NAMES[@]}"' _ "$ROOT" 2>&1)
assert_eq "5" "$OUT"

finish
