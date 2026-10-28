#!/usr/bin/env bash
#
# omarchy-browser-support — core library.
#
# Everything the CLI does (install, remove, default, status, menu) is driven by
# lib/browsers.tsv. This file loads that registry, validates it, and implements
# the browser operations. It is sourced by bin/omarchy-browsers, lib/menu.sh and
# the test harness — it is not meant to be executed directly.
#
# Conventions:
#   * Nothing under /usr/share/omarchy is ever written to.
#   * Every mutating operation honours DRY_RUN=1 (prints the command instead).
#   * Functions return non-zero on failure; the dispatcher decides how loud to be.

# shellcheck shell=bash

set -euo pipefail

# shellcheck disable=SC2034 # read by bin/omarchy-browsers
OMARCHY_BROWSERS_VERSION="1.0.0"
OMARCHY_BROWSERS_ROOT="${OMARCHY_BROWSERS_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"
REGISTRY_FILE="${OMARCHY_BROWSERS_REGISTRY:-$OMARCHY_BROWSERS_ROOT/lib/browsers.tsv}"

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

if [[ -t 1 && -z ${NO_COLOR:-} ]]; then
  C_RESET=$'\033[0m'
  C_DIM=$'\033[2m'
  C_BOLD=$'\033[1m'
  C_CYAN=$'\033[36m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_RED=$'\033[31m'
else
  C_RESET='' C_DIM='' C_BOLD='' C_CYAN='' C_GREEN='' C_YELLOW='' C_RED=''
fi

info() { printf '%s%s%s\n' "$C_CYAN" "$*" "$C_RESET"; }
ok()   { printf '%s%s%s\n' "$C_GREEN" "$*" "$C_RESET"; }
warn() { printf '%swarning:%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
err()  { printf '%serror:%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; }
die()  { err "$*"; exit 1; }

# Run a command, or print it when DRY_RUN is set.
run_cmd() {
  if [[ -n ${DRY_RUN:-} ]]; then
    printf '%s[dry-run]%s %s\n' "$C_DIM" "$C_RESET" "$*"
    return 0
  fi
  "$@"
}

# Escape a string for a double-quoted JSON value.
json_escape() {
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/\\n}
  s=${s//$'\t'/\\t}
  printf '%s' "$s"
}

# Quote a word for a POSIX shell command line embedded in JSON.
shq() {
  local s=$1
  printf "'%s'" "${s//\'/\'\\\'\'}"
}

# ---------------------------------------------------------------------------
# Registry
# ---------------------------------------------------------------------------

# Field constants — keep in sync with lib/browsers.tsv's header.
TSV_NAME=0 TSV_DISPLAY=1 TSV_PACKAGES=2 TSV_SOURCE=3 TSV_COMMAND=4
TSV_DESKTOPS=5 TSV_GLYPH=6 TSV_MENU_GLYPH=7 TSV_ICON_FONT=8 TSV_PURGE=9

declare -a BROWSER_NAMES=()
declare -A BROWSER_DISPLAY=() BROWSER_PACKAGES=() BROWSER_SOURCE=()
declare -A BROWSER_COMMAND=() BROWSER_DESKTOPS=() BROWSER_GLYPH=()
declare -A BROWSER_MENU_GLYPH=() BROWSER_ICON_FONT=() BROWSER_PURGE=()
declare -a SPLIT_FIELDS=()

# split_tsv <line> — fills SPLIT_FIELDS, preserving empty fields.
# (`read` cannot do this: IFS whitespace collapses runs of tabs.)
split_tsv() {
  local rest=$1
  SPLIT_FIELDS=()
  while [[ $rest == *$'\t'* ]]; do
    SPLIT_FIELDS+=("${rest%%$'\t'*}")
    rest=${rest#*$'\t'}
  done
  SPLIT_FIELDS+=("$rest")
}

# decode_glyph <U+XXXX|literal> — turns a codepoint into the real character.
decode_glyph() {
  local value=$1 hex
  if [[ $value =~ ^U\+([0-9A-Fa-f]{4,6})$ ]]; then
    hex=$(printf '%08X' "$((16#${BASH_REMATCH[1]}))")
    printf '%b' "\\U$hex"
  else
    printf '%s' "$value"
  fi
}

registry_error() {
  die "invalid registry ($REGISTRY_FILE): $*"
}

load_registry() {
  [[ -f $REGISTRY_FILE ]] || die "registry not found: $REGISTRY_FILE"

  local line lineno=0 name display packages source command desktops
  local glyph menu_glyph icon_font purge path

  while IFS= read -r line || [[ -n $line ]]; do
    lineno=$((lineno + 1))

    # Blank lines and comments.
    if [[ -z ${line//[[:space:]]/} || $line == \#* ]]; then
      continue
    fi

    split_tsv "$line"
    if (( ${#SPLIT_FIELDS[@]} != 10 )); then
      registry_error "line $lineno has ${#SPLIT_FIELDS[@]} fields, expected 10"
    fi

    name=${SPLIT_FIELDS[TSV_NAME]}
    display=${SPLIT_FIELDS[TSV_DISPLAY]}
    packages=${SPLIT_FIELDS[TSV_PACKAGES]}
    source=${SPLIT_FIELDS[TSV_SOURCE]}
    command=${SPLIT_FIELDS[TSV_COMMAND]}
    desktops=${SPLIT_FIELDS[TSV_DESKTOPS]}
    glyph=${SPLIT_FIELDS[TSV_GLYPH]}
    menu_glyph=${SPLIT_FIELDS[TSV_MENU_GLYPH]}
    icon_font=${SPLIT_FIELDS[TSV_ICON_FONT]}
    purge=${SPLIT_FIELDS[TSV_PURGE]}

    [[ $name =~ ^[a-z0-9][a-z0-9-]*$ ]] ||
      registry_error "line $lineno: bad browser name '$name'"
    [[ -n $display ]] || registry_error "line $lineno: empty display name"
    [[ -n $packages ]] || registry_error "line $lineno: empty package list"
    [[ -n $command ]] || registry_error "line $lineno: empty command"
    [[ -n $desktops ]] || registry_error "line $lineno: empty desktop list"
    [[ $source == repo || $source == aur ]] ||
      registry_error "line $lineno: source must be 'repo' or 'aur', got '$source'"
    [[ -z ${BROWSER_DISPLAY[$name]+set} ]] ||
      registry_error "line $lineno: duplicate browser '$name'"

    # A purge path must stay inside $HOME: compare after stripping leading ~/ or $HOME/.
    for path in $purge; do
      if [[ $path == /* || $path == *..* ]]; then
        registry_error "line $lineno: unsafe purge path '$path'"
      fi
    done

    BROWSER_NAMES+=("$name")
    BROWSER_DISPLAY[$name]=$display
    BROWSER_PACKAGES[$name]=$packages
    BROWSER_SOURCE[$name]=$source
    BROWSER_COMMAND[$name]=$command
    BROWSER_DESKTOPS[$name]=$desktops
    BROWSER_GLYPH[$name]=$(decode_glyph "$glyph")
    BROWSER_ICON_FONT[$name]=$icon_font
    BROWSER_PURGE[$name]=$purge

    if [[ -n $menu_glyph ]]; then
      BROWSER_MENU_GLYPH[$name]=$(decode_glyph "$menu_glyph")
    else
      BROWSER_MENU_GLYPH[$name]=$(decode_glyph "$glyph")
    fi
  done <"$REGISTRY_FILE"

  (( ${#BROWSER_NAMES[@]} > 0 )) || die "registry is empty: $REGISTRY_FILE"
}

load_registry

# ---------------------------------------------------------------------------
# Registry accessors
# ---------------------------------------------------------------------------

browser_exists() { [[ -n ${BROWSER_DISPLAY[$1]+set} ]]; }

require_browser() {
  browser_exists "$1" ||
    die "unknown browser '$1' — known browsers: ${BROWSER_NAMES[*]}"
}

browser_display() { printf '%s' "${BROWSER_DISPLAY[$1]}"; }
browser_source() { printf '%s' "${BROWSER_SOURCE[$1]}"; }

# Managed rows win; Omarchy's stock browsers fall back to their own table so
# `status`/`doctor` can describe both kinds through one accessor.
browser_command() {
  if [[ -n ${BROWSER_COMMAND[$1]+set} ]]; then
    printf '%s' "${BROWSER_COMMAND[$1]}"
  elif [[ -n ${STOCK_COMMAND[$1]+set} ]]; then
    printf '%s' "${STOCK_COMMAND[$1]}"
  fi
}
browser_glyph() { printf '%s' "${BROWSER_GLYPH[$1]}"; }
browser_menu_glyph() { printf '%s' "${BROWSER_MENU_GLYPH[$1]}"; }
browser_icon_font() { printf '%s' "${BROWSER_ICON_FONT[$1]}"; }
browser_primary_package() { printf '%s' "${BROWSER_PACKAGES[$1]%%,*}"; }

# browser_packages <name> <array-name>
browser_packages() {
  # shellcheck disable=SC2178 # nameref target is an array in every caller
  local -n _out=$2
  IFS=',' read -r -a _out <<<"${BROWSER_PACKAGES[$1]}"
}

# browser_desktops <name> <array-name>
browser_desktops() {
  # shellcheck disable=SC2178 # nameref target is an array in every caller
  local -n _out=$2
  IFS=',' read -r -a _out <<<"${BROWSER_DESKTOPS[$1]}"
}

is_stock_browser() { [[ -n ${STOCK_DESKTOP[$1]+set} ]]; }

# ---------------------------------------------------------------------------
# Browsers Omarchy ships (used for default-browser fallbacks)
# ---------------------------------------------------------------------------

declare -A STOCK_DESKTOP=(
  [chromium]=chromium.desktop
  [chrome]=google-chrome.desktop
  [brave]=brave-browser.desktop
  [brave-origin]=brave-origin.desktop
  [edge]=microsoft-edge.desktop
  [firefox]=firefox.desktop
  [zen]=zen.desktop
)

declare -A STOCK_COMMAND=(
  [chromium]=chromium
  [chrome]=google-chrome-stable
  [brave]=brave
  [brave-origin]=brave-origin
  [edge]=microsoft-edge-stable
  [firefox]=firefox
  [zen]=zen-browser
)

declare -A STOCK_DISPLAY=(
  [chromium]=Chromium
  [chrome]=Chrome
  [brave]=Brave
  [brave-origin]='Brave Origin'
  [edge]=Edge
  [firefox]=Firefox
  [zen]=Zen
)

declare -A STOCK_GLYPH=(
  [chromium]=U+F268
  [chrome]=U+F02AF
  [brave]=U+F059F
  [brave-origin]=U+F059F
  [edge]=U+F01E9
  [firefox]=U+F0239
  [zen]=U+F059F
)

# Whatever survives first wins when the current default browser goes away.
STOCK_FALLBACK_ORDER=(chromium firefox brave-origin brave chrome edge zen)

# ---------------------------------------------------------------------------
# Package helpers
# ---------------------------------------------------------------------------

pkg_present() {
  if command -v omarchy-pkg-present >/dev/null 2>&1; then
    omarchy-pkg-present "$@"
  elif command -v pacman >/dev/null 2>&1; then
    local p
    for p in "$@"; do pacman -Qq "$p" >/dev/null 2>&1 || return 1; done
  else
    return 1
  fi
}

pkg_missing() {
  if command -v omarchy-pkg-missing >/dev/null 2>&1; then
    omarchy-pkg-missing "$@"
  elif command -v pacman >/dev/null 2>&1; then
    local p
    for p in "$@"; do pacman -Qq "$p" >/dev/null 2>&1 || return 0; done
    return 1
  else
    return 0
  fi
}

cmd_present() {
  if command -v omarchy-cmd-present >/dev/null 2>&1; then
    omarchy-cmd-present "$1"
  else
    command -v "$1" >/dev/null 2>&1
  fi
}

browser_installed() {
  local -a pkgs
  browser_packages "$1" pkgs
  pkg_present "${pkgs[@]}"
}

# A browser with several packages counts as installed while any part remains —
# otherwise a half-removed Vivaldi would look like it was never there.
browser_installed_any() {
  local -a pkgs
  local p
  browser_packages "$1" pkgs
  for p in "${pkgs[@]}"; do
    pkg_present "$p" && return 0
  done
  return 1
}

browser_runnable() { cmd_present "$(browser_command "$1")"; }

# ---------------------------------------------------------------------------
# .desktop detection
# ---------------------------------------------------------------------------

desktop_data_dirs() {
  local dir
  local IFS=:
  # shellcheck disable=SC2086 # deliberate word splitting on ':'
  for dir in ${XDG_DATA_HOME:-$HOME/.local/share} ${XDG_DATA_DIRS:-/usr/local/share:/usr/share}; do
    [[ -n $dir ]] && printf '%s\n' "$dir"
  done
}

desktop_exec_command() {
  local file=$1 line token
  line=$(sed -n 's/^Exec=//p' "$file" 2>/dev/null | head -n1) || return 1
  [[ -n $line ]] || return 1
  token=${line%% *}
  token=${token#\"}
  token=${token%\"}
  printf '%s' "${token##*/}"
}

# detect_desktop <name> — prints the desktop id that belongs to the browser.
# Tries the declared ids first, then falls back to matching Exec= against the
# browser's command, so a package that renames its entry still resolves.
detect_desktop() {
  local name=$1 id dir file command
  local -a candidates

  browser_desktops "$name" candidates
  command=$(browser_command "$name")

  for id in "${candidates[@]}"; do
    while IFS= read -r dir; do
      if [[ -r $dir/applications/$id ]]; then
        printf '%s\n' "$id"
        return 0
      fi
    done < <(desktop_data_dirs)
  done

  while IFS= read -r dir; do
    [[ -d $dir/applications ]] || continue
    for file in "$dir"/applications/*.desktop; do
      [[ -r $file ]] || continue
      if [[ $(desktop_exec_command "$file" || true) == "$command" ]]; then
        printf '%s\n' "${file##*/}"
        return 0
      fi
    done
  done < <(desktop_data_dirs)

  return 1
}

# ---------------------------------------------------------------------------
# Current default browser
# ---------------------------------------------------------------------------

current_default_desktop() {
  local desktop=''
  if command -v omarchy-cmd-default-browser >/dev/null 2>&1; then
    desktop=$(omarchy-cmd-default-browser 2>/dev/null || true)
  fi
  if [[ -z $desktop || $desktop == omarchy-browser.desktop ]] &&
    command -v xdg-mime >/dev/null 2>&1; then
    desktop=$(xdg-mime query default x-scheme-handler/https 2>/dev/null || true)
  fi
  # omarchy-browser.desktop is Omarchy's own redirect stubs, not a browser.
  [[ $desktop == omarchy-browser.desktop ]] && desktop=''
  printf '%s' "$desktop"
}

# check_default <name> — succeeds when the browser owns the http(s) handler.
check_default() {
  local name=$1 desktop current
  current=$(current_default_desktop)

  if is_stock_browser "$name"; then
    desktop=${STOCK_DESKTOP[$name]}
  elif browser_exists "$name"; then
    desktop=$(detect_desktop "$name" 2>/dev/null) || return 1
  else
    return 1
  fi

  [[ -n $current && $current == "$desktop" ]]
}

# ---------------------------------------------------------------------------
# Set the default browser
# ---------------------------------------------------------------------------

browser_label() {
  if is_stock_browser "$1"; then
    printf '%s' "${STOCK_DISPLAY[$1]}"
  elif browser_exists "$1"; then
    browser_display "$1"
  else
    printf '%s' "$1"
  fi
}

browser_notify_glyph() {
  if is_stock_browser "$1"; then
    decode_glyph "${STOCK_GLYPH[$1]}"
  elif browser_exists "$1"; then
    browser_glyph "$1"
  fi
}

set_default_browser() {
  local name=$1 desktop label glyph got

  if is_stock_browser "$name"; then
    desktop=${STOCK_DESKTOP[$name]}
  elif browser_exists "$name"; then
    if ! desktop=$(detect_desktop "$name"); then
      # A preview is still useful before the browser is installed: fall back
      # to the preferred declared id instead of refusing to print anything.
      if [[ -n ${DRY_RUN:-} ]]; then
        local -a candidates
        browser_desktops "$name" candidates
        desktop=${candidates[0]}
      else
        die "$(browser_display "$name") is not installed (no .desktop entry found)"
      fi
    fi
  else
    die "unknown browser '$name' — known browsers: ${BROWSER_NAMES[*]} ${!STOCK_DESKTOP[*]}"
  fi

  label=$(browser_label "$name")
  glyph=$(browser_notify_glyph "$name")

  # xdg-settings verifies its own write by reading the handler back. The
  # session points $BROWSER (and the desktop-specific list) at
  # omarchy-browser.desktop, so hide both to let it read the real entry.
  run_cmd env -u BROWSER XDG_CURRENT_DESKTOP= xdg-settings set default-web-browser "$desktop" ||
    die "xdg-settings failed to set $desktop"

  if [[ -z ${DRY_RUN:-} ]]; then
    got=$(current_default_desktop)
    if [[ $got != "$desktop" ]]; then
      run_cmd env -u BROWSER XDG_CURRENT_DESKTOP= xdg-mime default "$desktop" \
        x-scheme-handler/http x-scheme-handler/https ||
        die "xdg-mime fallback failed"
      got=$(current_default_desktop)
      [[ $got == "$desktop" ]] ||
        die "could not make $desktop the default (reader sees: ${got:-nothing})"
    fi

    if command -v omarchy-notification-send >/dev/null 2>&1; then
      omarchy-notification-send -g "$glyph" "$label is now the default browser" >/dev/null 2>&1 || true
    fi
  fi

  ok "$label is now the default browser."
}

# ---------------------------------------------------------------------------
# Install / remove
# ---------------------------------------------------------------------------

install_browser() {
  local name=$1 display source primary
  local -a pkgs
  local desktop

  require_browser "$name"
  display=$(browser_display "$name")
  source=$(browser_source "$name")
  browser_packages "$name" pkgs
  primary=${pkgs[0]}

  if pkg_present "${pkgs[@]}"; then
    ok "$display is already installed."
    if desktop=$(detect_desktop "$name" 2>/dev/null); then
      info "desktop entry: $desktop"
    fi
    return 0
  fi

  info "Installing $display (${pkgs[*]}) from $([[ $source == aur ]] && echo 'the AUR' || echo 'the official repositories')…"

  case $source in
  repo)
    run_cmd omarchy pkg add "${pkgs[@]}" || die "failed to install ${pkgs[*]}"
    ;;
  aur)
    if command -v omarchy >/dev/null 2>&1; then
      omarchy pkg aur accessible >/dev/null 2>&1 ||
        warn "AUR availability check failed — trying anyway."
    fi
    run_cmd omarchy pkg aur add "${pkgs[@]}" ||
      die "failed to install ${pkgs[*]} from the AUR"
    ;;
  esac

  [[ -n ${DRY_RUN:-} ]] && return 0

  pkg_present "$primary" || die "$primary did not install correctly"

  echo
  ok "$display installed."
  if desktop=$(detect_desktop "$name" 2>/dev/null); then
    info "desktop entry: $desktop"
  else
    warn "no .desktop entry found — try logging out and back in, then rerun 'omarchy-browsers status'."
  fi
  printf 'Make it the default:  %s default %s\n' \
    "${OMARCHY_BROWSERS_BIN:-omarchy-browsers}" "$name"
}

purge_browser_paths() {
  local name=$1 path full
  require_browser "$name"
  for path in ${BROWSER_PURGE[$name]}; do
    full=$HOME/${path#\~/}
    if [[ -e $full ]]; then
      warn "purging $full"
      run_cmd rm -rf -- "$full"
    fi
  done
}

# pick_fallback_default <exclude-name> — prints a browser to take over, if any.
pick_fallback_default() {
  local exclude=$1 name

  for name in "${STOCK_FALLBACK_ORDER[@]}"; do
    [[ $name == "$exclude" ]] && continue
    cmd_present "${STOCK_COMMAND[$name]}" && { printf '%s\n' "$name"; return 0; }
  done

  for name in "${BROWSER_NAMES[@]}"; do
    [[ $name == "$exclude" ]] && continue
    detect_desktop "$name" >/dev/null 2>&1 && { printf '%s\n' "$name"; return 0; }
  done

  return 1
}

remove_browser() {
  local name=$1 purge=${2:-} display current fallback
  local -a pkgs

  require_browser "$name"
  display=$(browser_display "$name")
  browser_packages "$name" pkgs

  if ! browser_installed_any "$name"; then
    if [[ $purge == --purge ]]; then
      purge_browser_paths "$name"
      ok "$display was not installed; leftover profile data purged."
    else
      ok "$display is not installed — nothing to remove."
    fi
    return 0
  fi

  # If this browser is the default, hand the handler to a survivor first.
  current=$(current_default_desktop)
  if [[ -n $current ]] && check_default "$name"; then
    if fallback=$(pick_fallback_default "$name"); then
      info "$display is the default — switching the default to $(browser_label "$fallback")…"
      set_default_browser "$fallback" ||
        warn "could not switch the default automatically; pick one in Setup › Defaults › Browser."
    else
      warn "$display is the default and no other browser is installed."
      warn "Install another browser and set it in Setup › Defaults › Browser."
    fi
  fi

  info "Removing $display (${pkgs[*]})…"
  run_cmd omarchy pkg drop "${pkgs[@]}" || die "failed to remove ${pkgs[*]}"

  if [[ $purge == --purge ]]; then
    purge_browser_paths "$name"
  fi

  [[ -n ${DRY_RUN:-} ]] && return 0

  pkg_missing "${pkgs[0]}" || die "${pkgs[0]} is still installed"
  ok "$display removed.$([[ $purge == --purge ]] && echo ' Profile data purged.')"
}

# ---------------------------------------------------------------------------
# Reporting
# ---------------------------------------------------------------------------

status_header() {
  printf '%s%-11s %-11s %-10s %-8s %-24s %s%s\n' \
    "$C_BOLD" NAME DISPLAY INSTALLED DEFAULT 'DESKTOP ENTRY' COMMAND "$C_RESET"
}

print_status() {
  local current
  current=$(current_default_desktop)
  if [[ -n $current ]]; then
    info "Default browser: $current"
  else
    warn "No default browser is set."
  fi

  echo
  status_header
  local name installed default desktop
  for name in "${BROWSER_NAMES[@]}"; do
    installed='no'
    browser_installed "$name" && installed='yes'
    default='·'
    check_default "$name" && default='✓'
    desktop='—'
    desktop=$(detect_desktop "$name" 2>/dev/null || printf '—')
    printf '%-11s %-11s %-10s %-8s %-24s %s\n' \
      "$name" "$(browser_display "$name")" "$installed" "$default" \
      "$desktop" "$(browser_command "$name")"
  done
}

print_status_json() {
  local name first=1 current os_version
  current=$(current_default_desktop)

  os_version=''
  if command -v omarchy >/dev/null 2>&1; then
    os_version=$(omarchy version 2>/dev/null | head -n1 || true)
  fi

  printf '{\n'
  printf '  "schema": 1,\n'
  printf '  "omarchy_version": "%s",\n' "$(json_escape "$os_version")"
  printf '  "default_browser": "%s",\n' "$(json_escape "$current")"
  printf '  "browsers": [\n'

  for name in "${BROWSER_NAMES[@]}"; do
    local desktop='' installed=false is_default=false packages_json=''
    local -a pkgs
    local pkg
    browser_packages "$name" pkgs
    browser_installed "$name" && installed=true
    check_default "$name" && is_default=true
    desktop=$(detect_desktop "$name" 2>/dev/null || true)
    for pkg in "${pkgs[@]}"; do
      packages_json+="${packages_json:+,}\"$(json_escape "$pkg")\""
    done

    (( first )) || printf ',\n'
    first=0
    printf '    {"name": "%s", "display": "%s", "packages": [%s], "source": "%s", "command": "%s", "desktop": "%s", "installed": %s, "default": %s}' \
      "$(json_escape "$name")" \
      "$(json_escape "$(browser_display "$name")")" \
      "$packages_json" \
      "$(json_escape "$(browser_source "$name")")" \
      "$(json_escape "$(browser_command "$name")")" \
      "$(json_escape "$desktop")" \
      "$installed" "$is_default"
  done

  printf '\n  ]\n}\n'
}

print_browser_table() {
  printf '%s%-11s %-11s %-6s %-40s %s%s\n' \
    "$C_BOLD" NAME DISPLAY SOURCE PACKAGES COMMAND "$C_RESET"
  local name
  for name in "${BROWSER_NAMES[@]}"; do
    printf '%-11s %-11s %-6s %-40s %s\n' \
      "$name" "$(browser_display "$name")" "$(browser_source "$name")" \
      "${BROWSER_PACKAGES[$name]}" "$(browser_command "$name")"
  done
}
