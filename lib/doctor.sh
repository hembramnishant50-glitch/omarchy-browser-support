#!/usr/bin/env bash
#
# omarchy-browser-support — self-diagnostics.
#
# `omarchy-browsers doctor` answers the question "why is this not working?"
# without the user having to read the source. Every check prints OK, WARN or
# FAIL; warnings are survivable, failures exit non-zero so CI and scripts can
# rely on the result.
#
# shellcheck shell=bash

DOCTOR_FAILS=0
DOCTOR_WARNS=0

doctor_ok()   { printf '%s  ok  %s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
doctor_warn() { printf '%s warn %s %s\n' "$C_YELLOW" "$C_RESET" "$*"; DOCTOR_WARNS=$((DOCTOR_WARNS + 1)); }
doctor_fail() { printf '%s fail %s %s\n' "$C_RED" "$C_RESET" "$*"; DOCTOR_FAILS=$((DOCTOR_FAILS + 1)); }
doctor_head() { printf '\n%s%s%s\n' "$C_BOLD" "$*" "$C_RESET"; }

doctor_check_environment() {
  doctor_head "Environment"

  if (( BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 3) )); then
    doctor_ok "bash ${BASH_VERSION%%(*}"
  else
    doctor_fail "bash 4.3+ required (found ${BASH_VERSION%%(*})"
  fi

  if [[ -d $OMARCHY_PATH ]]; then
    local version='unknown'
    command -v omarchy >/dev/null 2>&1 && version=$(omarchy version 2>/dev/null | head -n1 || true)
    doctor_ok "Omarchy $version at $OMARCHY_PATH"
  else
    doctor_fail "Omarchy not found at $OMARCHY_PATH (set OMARCHY_PATH if it lives elsewhere)"
  fi

  case $OMARCHY_BROWSERS_ROOT in
  /usr/share/omarchy/* | "$OMARCHY_PATH"/*)
    doctor_fail "this project must not live under $OMARCHY_PATH — move it to your home directory"
    ;;
  *)
    doctor_ok "project root: $OMARCHY_BROWSERS_ROOT"
    ;;
  esac

  local tool
  for tool in omarchy pacman xdg-settings xdg-mime; do
    if command -v "$tool" >/dev/null 2>&1; then
      doctor_ok "command available: $tool"
    else
      doctor_fail "missing required command: $tool"
    fi
  done

  for tool in node fc-cache; do
    if command -v "$tool" >/dev/null 2>&1; then
      doctor_ok "command available: $tool"
    else
      doctor_warn "optional command missing: $tool"
    fi
  done
}

doctor_check_registry() {
  doctor_head "Registry"
  doctor_ok "${#BROWSER_NAMES[@]} browsers: ${BROWSER_NAMES[*]}"

  local name source
  for name in "${BROWSER_NAMES[@]}"; do
    source=$(browser_source "$name")
    if [[ $source == aur ]] && ! command -v yay >/dev/null 2>&1; then
      doctor_warn "$name comes from the AUR and yay is not installed (Omarchy installs it on demand)"
    fi
  done
}

doctor_check_menu() {
  doctor_head "Menu integration"

  if [[ -f $MENU_MODEL ]]; then
    doctor_ok "Omarchy menu model found"
  else
    doctor_fail "Omarchy menu model missing: $MENU_MODEL"
  fi

  if [[ ! -f $MENU_FILE ]]; then
    doctor_warn "menu file does not exist yet: $MENU_FILE (run 'omarchy-browsers menu setup')"
    return 0
  fi

  doctor_ok "menu file: $MENU_FILE"

  if grep -qF "$BEGIN_MARK" "$MENU_FILE"; then
    doctor_ok "managed block present"
  else
    doctor_warn "managed block missing (run 'omarchy-browsers menu setup')"
  fi

  if grep -qF "$LEGACY_BEGIN_MARK" "$MENU_FILE"; then
    doctor_warn "legacy menu block from the pre-1.0 scripts found (run 'omarchy-browsers menu setup')"
  fi

  local family
  while IFS= read -r family; do
    [[ -n $family ]] || continue
    if menu_font_installed "$family"; then
      doctor_ok "icon font installed: $family"
    else
      doctor_warn "icon font missing: $family (run 'omarchy-browsers menu setup')"
    fi
  done < <(menu_icon_fonts)

  if command -v node >/dev/null 2>&1 && [[ -f $MENU_MODEL ]]; then
    if out=$(validate_menu "$MENU_FILE" 2>&1); then
      doctor_ok "menu file parses and merges cleanly ($out)"
    else
      doctor_fail "menu file does not validate: $out"
    fi
  fi
}

doctor_check_default() {
  doctor_head "Default browser"

  if ! command -v omarchy-cmd-default-browser >/dev/null 2>&1; then
    doctor_warn "omarchy-cmd-default-browser is missing — the ✓ marks will not work"
    return 0
  fi

  local current
  current=$(current_default_desktop)
  if [[ -z $current ]]; then
    doctor_warn "no default browser is set (Setup › Defaults › Browser)"
    return 0
  fi

  local dir found=0
  while IFS= read -r dir; do
    if [[ -r $dir/applications/$current ]]; then
      found=1
      local exec_cmd
      exec_cmd=$(sed -n 's/^Exec=//p' "$dir/applications/$current" | head -n1 | awk '{print $1}')
      if [[ -n $exec_cmd ]] && cmd_present "$exec_cmd"; then
        doctor_ok "default browser: $current (Exec: $exec_cmd)"
      else
        doctor_warn "default browser $current points at a missing command: ${exec_cmd:-<empty>}"
      fi
      break
    fi
  done < <(desktop_data_dirs)

  (( found )) || doctor_warn "default browser $current has no .desktop entry on this system"
}

doctor_check_browsers() {
  doctor_head "Browsers"

  local name display installed desktop command
  for name in "${BROWSER_NAMES[@]}"; do
    display=$(browser_display "$name")
    command=$(browser_command "$name")
    installed=no
    desktop=''

    browser_installed "$name" && installed=yes
    desktop=$(detect_desktop "$name" 2>/dev/null || true)

    if [[ $installed == no ]]; then
      doctor_ok "$display: not installed (${BROWSER_PACKAGES[$name]}, ${BROWSER_SOURCE[$name]})"
      continue
    fi

    if [[ -n $desktop ]]; then
      doctor_ok "$display: installed, desktop entry $desktop"
    else
      doctor_fail "$display: installed but no .desktop entry found"
    fi

    if cmd_present "$command"; then
      doctor_ok "$display: command $command resolves"
    else
      doctor_fail "$display: command $command is missing"
    fi
  done
}

doctor_check_aur() {
  doctor_head "Repositories"
  if [[ -n ${DRY_RUN:-} ]]; then
    doctor_ok "AUR reachability skipped (dry run)"
    return 0
  fi
  if ! command -v omarchy >/dev/null 2>&1; then
    return 0
  fi
  if omarchy pkg aur accessible >/dev/null 2>&1; then
    doctor_ok "AUR is reachable"
  else
    doctor_warn "AUR is not reachable — Waterfox and Floorp cannot be installed right now"
  fi
}

doctor_summary() {
  echo
  if (( DOCTOR_FAILS > 0 )); then
    printf '%s%d failure(s), %d warning(s)%s\n' "$C_RED" "$DOCTOR_FAILS" "$DOCTOR_WARNS" "$C_RESET"
    return 1
  fi
  if (( DOCTOR_WARNS > 0 )); then
    printf '%sall checks passed, %d warning(s)%s\n' "$C_YELLOW" "$DOCTOR_WARNS" "$C_RESET"
    return 0
  fi
  printf '%sall checks passed%s\n' "$C_GREEN" "$C_RESET"
}

doctor_run() {
  DOCTOR_FAILS=0
  DOCTOR_WARNS=0
  doctor_check_environment
  doctor_check_registry
  doctor_check_menu
  doctor_check_default
  doctor_check_browsers
  doctor_check_aur
  doctor_summary
}
