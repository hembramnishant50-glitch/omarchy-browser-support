#!/usr/bin/env bash
#
# omarchy-browsers — shared registry and core operations.
# Sourced by every install-*.sh, remove-*.sh, set-default.sh and menu-*.sh.
#
# One source of truth: every browser Omarchy does not ship is described in
# BROWSER_REGISTRY below, and the menu rows, installers, removers and the
# default-browser setter are all generated from it.

set -euo pipefail

OMARCHY_BROWSERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"

# ---------------------------------------------------------------------------
# Registry
# ---------------------------------------------------------------------------
# Fields (pipe separated):
#   1 name        CLI argument and menu id suffix  (install.browser.<name>)
#   2 display     Human name shown in the menu
#   3 packages    Comma separated. FIRST package is the "primary" one and
#                 drives menu visibility and install/remove decisions.
#   4 source      repo (official Arch repos) | aur (AUR via yay)
#   5 command     Executable name — used by `omarchy-cmd-present` menu guards
#                 and to detect the .desktop entry at default-setting time.
#   6 desktops    Comma separated .desktop id candidates (first = primary).
#                 Checked in order, then a Exec= match is used as fallback.
#   7 glyph       Nerd Font glyph used by the default-browser notification
#   8 menu glyph  (optional) glyph used by the MENU rows instead of field 7.
#                 Needed when the icon lives in a custom icon font (field 9).
#   9 icon font   (optional) Qt font family rendering field 8. Empty means
#                 the menu's normal Nerd Font. Built by
#                 assets/build-helium-icon-font.py and installed to
#                 ~/.local/share/fonts/ by menu-setup.sh.
# ---------------------------------------------------------------------------
BROWSER_REGISTRY=(
  "helium|Helium|helium-browser-bin|repo|helium-browser|helium.desktop|󰊠||OmarchyHeliumIcon"
  "librewolf|LibreWolf|librewolf|repo|librewolf|librewolf.desktop|󰖟"
  "waterfox|Waterfox|waterfox-bin|aur|waterfox|waterfox.desktop|"
  "vivaldi|Vivaldi|vivaldi,vivaldi-ffmpeg-codecs|repo|vivaldi|vivaldi-stable.desktop,vivaldi.desktop|󰊯"
)

NEW_BROWSER_NAMES=(helium librewolf waterfox vivaldi)

# Desktop ids of the browsers Omarchy ships (for default-setting fallbacks).
declare -A STOCK_BROWSER_DESKTOP=(
  [chromium]=chromium.desktop
  [chrome]=google-chrome.desktop
  [brave]=brave-browser.desktop
  [brave-origin]=brave-origin.desktop
  [edge]=microsoft-edge.desktop
  [firefox]=firefox.desktop
  [zen]=zen.desktop
)

# Preference order used when the current default browser is removed:
# whatever survives first wins.
DEFAULT_FALLBACK_ORDER=(chromium firefox brave-origin brave chrome edge zen helium librewolf waterfox vivaldi)

# Data/config/cache directories wiped by `remove-*.sh --purge`.
declare -A BROWSER_PURGE_PATHS=(
  [helium]="$HOME/.config/helium $HOME/.local/share/helium $HOME/.cache/helium"
  [librewolf]="$HOME/.librewolf $HOME/.config/librewolf $HOME/.cache/librewolf"
  [waterfox]="$HOME/.waterfox $HOME/.config/waterfox $HOME/.local/share/waterfox $HOME/.cache/waterfox"
  [vivaldi]="$HOME/.config/vivaldi $HOME/.local/share/vivaldi $HOME/.cache/vivaldi"
)

# ---------------------------------------------------------------------------
# Small helpers
# ---------------------------------------------------------------------------

info() { printf '\033[36m%s\033[0m\n' "$*"; }
ok()   { printf '\033[32m%s\033[0m\n' "$*"; }
warn() { printf '\033[33m%s\033[0m\n' "$*" >&2; }
die()  { printf '\033[31mError:\033[0m %s\n' "$*" >&2; exit 1; }

# Run a command, or just print it when DRY_RUN=1 is set (used for testing).
run_cmd() {
  if [[ -n ${DRY_RUN:-} ]]; then
    printf '[dry-run] %s\n' "$*"
    return 0
  fi
  "$@"
}

# registry_field <name> <1-based field number>
registry_field() {
  local name=$1 idx=$2 row
  for row in "${BROWSER_REGISTRY[@]}"; do
    if [[ ${row%%|*} == "$name" ]]; then
      local IFS='|'
      local -a parts
      # Append a separator so a trailing EMPTY field survives the split.
      read -r -a parts <<<"${row}|"
      printf '%s' "${parts[$((idx - 1))]:-}"
      return 0
    fi
  done
  return 1
}

browser_display()  { registry_field "$1" 2; }
browser_source()   { registry_field "$1" 4; }
browser_cmd()      { registry_field "$1" 5; }
browser_glyph()    { registry_field "$1" 7; }
browser_menu_glyph() {
  local g
  g=$(registry_field "$1" 8)
  if [[ -n $g ]]; then printf '%s' "$g"; else registry_field "$1" 7; fi
}
browser_icon_font() { registry_field "$1" 9; }

# browser_pkgs <name> <array-name>   — fills the named array with packages.
browser_pkgs() {
  local name=$1 out=$2 csv
  csv=$(registry_field "$name" 3) || die "unknown browser: $name"
  IFS=',' read -r -a "$out" <<<"$csv"
}

# browser_desktop_candidates <name> <array-name>
browser_desktop_candidates() {
  local name=$1 out=$2 csv
  csv=$(registry_field "$name" 6) || die "unknown browser: $name"
  IFS=',' read -r -a "$out" <<<"$csv"
}

is_new_browser() {
  local n
  for n in "${NEW_BROWSER_NAMES[@]}"; do [[ $n == "$1" ]] && return 0; done
  return 1
}

is_stock_browser() {
  [[ -n ${STOCK_BROWSER_DESKTOP[$1]+x} ]]
}

require_new_browser() {
  is_new_browser "$1" || die "unknown browser '$1'. Known: ${NEW_BROWSER_NAMES[*]}"
}

# Data dirs searched for .desktop entries, in XDG order.
desktop_data_dirs() {
  printf '%s\n' "${XDG_DATA_HOME:-$HOME/.local/share}" /usr/local/share /usr/share
}

# detect_desktop <name> -> prints the installed .desktop id (or fails).
# 1. try the declared candidates, 2. fall back to matching Exec= against the
# browser command, so a package that ships an unexpected id still resolves.
detect_desktop() {
  local name=$1
  local -a candidates pkgs
  local cmd dir id f exec_line

  browser_desktop_candidates "$name" candidates || return 1
  cmd=$(browser_cmd "$name")

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
    for f in "$dir"/applications/*.desktop; do
      [[ -r $f ]] || continue
      exec_line=$(sed -n 's/^Exec=\([^ ]*\).*/\1/p' "$f" | head -1)
      if [[ ${exec_line##*/} == "$cmd" ]]; then
        printf '%s\n' "${f##*/}"
        return 0
      fi
    done
  done < <(desktop_data_dirs)

  return 1
}

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------

install_browser() {
  local name=$1
  require_new_browser "$name"

  local display source
  local -a pkgs
  display=$(browser_display "$name")
  source=$(browser_source "$name")
  browser_pkgs "$name" pkgs

  if omarchy-pkg-present "${pkgs[@]}"; then
    ok "$display is already installed."
    return 0
  fi

  info "Installing $display (${pkgs[*]}) from $([[ $source == aur ]] && echo AUR || echo 'official repos')..."

  case $source in
  repo) run_cmd omarchy pkg add "${pkgs[@]}" || die "failed to install ${pkgs[*]}" ;;
  aur)
    omarchy pkg aur accessible >/dev/null 2>&1 || warn "AUR reachability check failed — trying anyway."
    run_cmd omarchy pkg aur add "${pkgs[@]}" || die "failed to install ${pkgs[*]} from the AUR"
    ;;
  *) die "unknown source '$source' for $name" ;;
  esac

  [[ -n ${DRY_RUN:-} ]] && return 0

  omarchy-pkg-present "${pkgs[0]}" || die "${pkgs[0]} did not install"

  echo ""
  ok "$display installed."
  echo "Make it the default:  ./set-default.sh $name"
  echo "(or via the menu: Setup > Defaults > Browser)"
}

# ---------------------------------------------------------------------------
# Remove
# ---------------------------------------------------------------------------

# pick_fallback_default <exclude-name> -> prints a browser name to become the
# new default, or fails when nothing else is installed.
pick_fallback_default() {
  local exclude=$1 name desktop

  for name in "${DEFAULT_FALLBACK_ORDER[@]}"; do
    [[ $name == "$exclude" ]] && continue
    if is_stock_browser "$name"; then
      local desktop=${STOCK_BROWSER_DESKTOP[$name]}
      local cmd
      case $name in
      chromium) cmd=chromium ;;
      chrome) cmd=google-chrome-stable ;;
      brave) cmd=brave ;;
      brave-origin) cmd=brave-origin ;;
      edge) cmd=microsoft-edge-stable ;;
      firefox) cmd=firefox ;;
      zen) cmd=zen-browser ;;
      esac
      if omarchy-cmd-present "$cmd"; then
        printf '%s\n' "$name"
        return 0
      fi
    elif is_new_browser "$name"; then
      if detect_desktop "$name" >/dev/null; then
        printf '%s\n' "$name"
        return 0
      fi
    fi
  done

  return 1
}

# Delete a browser's profile/config/cache directories (the --purge paths).
purge_browser_paths() {
  local name=$1 paths expanded p
  paths=$(printf '%s' "${BROWSER_PURGE_PATHS[$name]:-}")
  for p in $paths; do
    expanded=${p/#\~/$HOME}
    if [[ -e $expanded ]]; then
      warn "purging $expanded"
      run_cmd rm -rf -- "$expanded"
    fi
  done
}

remove_browser() {
  local name=$1
  local purge=${2:-}
  require_new_browser "$name"

  local display
  local -a pkgs
  display=$(browser_display "$name")
  browser_pkgs "$name" pkgs

  if omarchy-pkg-missing "${pkgs[@]}"; then
    if [[ $purge == "--purge" ]]; then
      # Package is already gone, but leftover profile/cache data may remain —
      # --purge should still wipe it.
      purge_browser_paths "$name"
      ok "$display was not installed; leftover profile data purged (if any)."
    else
      ok "$display is not installed — nothing to remove."
    fi
    return 0
  fi

  # If the browser being removed is the current default, hand the default
  # over to something that survives before xdg loses its handler.
  local current fb
  current=$(omarchy-cmd-default-browser 2>/dev/null || true)
  if [[ -n $current ]] && detect_desktop "$name" >/dev/null 2>&1 && [[ $current == "$(detect_desktop "$name")" ]]; then
    if fb=$(pick_fallback_default "$name"); then
      info "$display was the default browser — switching default to $(browser_display "$fb")..."
      set_default_browser "$fb" || warn "could not switch the default browser automatically; set one via Setup > Defaults > Browser."
    else
      warn "$display was the default browser and no other browser is installed."
      warn "Install one later and set it via Setup > Defaults > Browser."
    fi
  fi

  info "Removing $display (${pkgs[*]})..."
  run_cmd omarchy pkg drop "${pkgs[@]}" || die "failed to remove ${pkgs[*]}"

  if [[ $purge == "--purge" ]]; then
    purge_browser_paths "$name"
  fi

  [[ -n ${DRY_RUN:-} ]] && return 0

  omarchy-pkg-missing "${pkgs[0]}" || die "${pkgs[0]} is still installed"
  ok "$display removed."$([[ $purge == "--purge" ]] && echo " Profile data purged.")
}

# ---------------------------------------------------------------------------
# Default browser
# ---------------------------------------------------------------------------

set_default_browser() {
  local name=$1
  local desktop display glyph

  if is_stock_browser "$name"; then
    desktop=${STOCK_BROWSER_DESKTOP[$name]}
    display=$name
    glyph=󰊯
  else
    require_new_browser "$name"
    desktop=$(detect_desktop "$name") || die "$(browser_display "$name") is not installed"
    display=$(browser_display "$name")
    glyph=$(browser_glyph "$name")
  fi

  # Same trick as stock omarchy-default-browser: xdg-settings reads $BROWSER
  # back and the session points it at omarchy-launch-browser, so it must go.
  run_cmd env -u BROWSER XDG_CURRENT_DESKTOP= xdg-settings set default-web-browser "$desktop" ||
    die "xdg-settings failed for $desktop"

  [[ -n ${DRY_RUN:-} ]] && return 0

  # Verify through the same reader the menu's ✓ marks use. If xdg-settings
  # landed somewhere the reader ignores, set the mime handler directly.
  local got
  got=$(omarchy-cmd-default-browser 2>/dev/null || true)
  if [[ $got != "$desktop" ]]; then
    run_cmd env -u BROWSER XDG_CURRENT_DESKTOP= xdg-mime default "$desktop" \
      x-scheme-handler/http x-scheme-handler/https || die "xdg-mime fallback failed"
    got=$(omarchy-cmd-default-browser 2>/dev/null || true)
    [[ $got == "$desktop" ]] || die "could not make $desktop the default (reader sees: ${got:-nothing})"
  fi

  command -v omarchy-notification-send >/dev/null 2>&1 &&
    omarchy-notification-send -g "$glyph" "$(browser_display_or_stock "$name") is now the default browser" || true

  ok "$(browser_display_or_stock "$name") is now the default browser."
}

browser_display_or_stock() {
  if is_new_browser "$1"; then browser_display "$1"; else printf '%s' "$1"; fi
}

# check_default <name> — exit 0 when this browser is the current default.
# Used by the menu's `checked:` expressions to draw the ✓.
check_default() {
  local name=$1 desktop

  if is_stock_browser "$name"; then
    desktop=${STOCK_BROWSER_DESKTOP[$name]}
  elif is_new_browser "$name"; then
    desktop=$(detect_desktop "$name" 2>/dev/null) || return 1
  else
    return 1
  fi

  [[ $(omarchy-cmd-default-browser 2>/dev/null) == "$desktop" ]]
}

print_default_status() {
  local current
  current=$(omarchy-cmd-default-browser 2>/dev/null || echo "")
  echo "Current default browser: ${current:-unknown}"
  echo ""
  echo "Set a default:  ./set-default.sh <browser>"
  echo ""
  printf '%-10s %-12s %-10s %s\n' "BROWSER" "INSTALLED" "DEFAULT" "COMMAND"
  local name
  for name in "${NEW_BROWSER_NAMES[@]}"; do
    local -a pkgs
    browser_pkgs "$name" pkgs
    local inst="no" def="" cmd
    omarchy-pkg-present "${pkgs[0]}" && inst="yes"
    check_default "$name" && def="YES"
    cmd=$(browser_cmd "$name")
    command -v "$cmd" >/dev/null 2>&1 || cmd="$cmd (missing)"
    printf '%-10s %-12s %-10s %s\n' "$name" "$inst" "${def:-—}" "$cmd"
  done
}
