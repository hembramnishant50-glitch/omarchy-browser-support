#!/usr/bin/env bash
#
# omarchy-browser-support — Omarchy menu integration.
#
# Omarchy merges ~/.config/omarchy/extensions/omarchy-menu.jsonc over its own
# menu definition. This file owns a single marked block inside that file:
#
#   Install › Browser          one row per browser, hidden once installed
#   Remove  › Browser          one row per browser, hidden once removed
#   Setup › Defaults › Browser one row per browser, with a ✓ on the current one
#
# The block is regenerated from lib/browsers.tsv on every `menu setup`, so the
# file stays human-editable everywhere else. Writes are atomic and skipped when
# nothing changed (idempotent), and the result is validated against Omarchy's
# own MenuModel.js before it replaces the live file.
#
# shellcheck shell=bash

OMARCHY_BROWSERS_BIN="${OMARCHY_BROWSERS_BIN:-$OMARCHY_BROWSERS_ROOT/bin/omarchy-browsers}"

MENU_FILE="${OMARCHY_BROWSERS_MENU_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/extensions/omarchy-menu.jsonc}"
DEFAULT_MENU_FILE="$OMARCHY_PATH/default/omarchy/omarchy-menu.jsonc"
MENU_MODEL="$OMARCHY_PATH/shell/plugins/menu/MenuModel.js"

BEGIN_MARK='// >>> omarchy-browser-support (managed block — edits are overwritten)'
END_MARK='// <<< omarchy-browser-support'

# Marker pair written by the pre-1.0 scripts (menu-setup.sh / menu-teardown.sh).
LEGACY_BEGIN_MARK='// >>> omarchy-browsers (managed block — regenerate with menu-setup.sh)'
LEGACY_END_MARK='// <<< omarchy-browsers'

FONT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"

# ---------------------------------------------------------------------------
# Icon fonts
# ---------------------------------------------------------------------------

# menu_icon_fonts — unique icon-font families the registry asks for.
menu_icon_fonts() {
  local name family
  local -A seen=()
  for name in "${BROWSER_NAMES[@]}"; do
    family=$(browser_icon_font "$name")
    [[ -n $family && -z ${seen[$family]+set} ]] || continue
    seen[$family]=1
    printf '%s\n' "$family"
  done
}

menu_font_source() { printf '%s/assets/%s.ttf' "$OMARCHY_BROWSERS_ROOT" "$1"; }

menu_font_installed() { [[ -f $FONT_DIR/$1.ttf ]]; }

# Fonts earlier versions installed but the registry no longer asks for. Kept as
# a list so upgrades can clean them up instead of leaving a stale family behind.
LEGACY_ICON_FONTS=()

menu_prune_legacy_fonts() {
  local family dst required
  required=$(menu_icon_fonts)
  for family in "${LEGACY_ICON_FONTS[@]}"; do
    [[ -n $family ]] || continue
    grep -qxF "$family" <<<"$required" && continue
    dst="$FONT_DIR/$family.ttf"
    [[ -f $dst ]] || continue
    run_cmd rm -f -- "$dst"
    info "removed obsolete menu icon font: $family"
  done
}

menu_install_fonts() {
  local family src dst installed_any=0
  while IFS= read -r family; do
    [[ -n $family ]] || continue
    src=$(menu_font_source "$family")
    dst="$FONT_DIR/$family.ttf"

    if [[ ! -f $src ]]; then
      warn "icon font source missing: $src (menu icons may show a placeholder)"
      continue
    fi

    if cmp -s "$src" "$dst" 2>/dev/null; then
      continue
    fi

    run_cmd install -Dm644 "$src" "$dst"
    installed_any=1
    info "installed menu icon font: $family"
  done < <(menu_icon_fonts)

  if (( installed_any )) && [[ -z ${DRY_RUN:-} ]]; then
    fc-cache -f "$FONT_DIR" >/dev/null 2>&1 ||
      warn "fc-cache failed — run 'fc-cache -f' if the icons do not appear."
    # Qt builds its font database at startup, so a shell that is already
    # running cannot see a family installed after it started.
    info "restart the Omarchy shell (or log out and back in) once so the new icon font is picked up"
  fi
}

menu_remove_fonts() {
  local family dst removed=0
  while IFS= read -r family; do
    [[ -n $family ]] || continue
    dst="$FONT_DIR/$family.ttf"
    [[ -f $dst ]] || continue
    run_cmd rm -f -- "$dst"
    removed=1
    info "removed menu icon font: $family"
  done < <(menu_icon_fonts)

  if (( removed )) && [[ -z ${DRY_RUN:-} ]]; then
    fc-cache -f "$FONT_DIR" >/dev/null 2>&1 || true
  fi
}

# ---------------------------------------------------------------------------
# Menu file handling
# ---------------------------------------------------------------------------

menu_file_exists_integration() {
  [[ -f $MENU_FILE ]] && grep -qF "$BEGIN_MARK" "$MENU_FILE"
}

# strip_managed_blocks <file> — prints the file without our block (current or
# the legacy pre-1.0 one), leaving every other line untouched.
strip_managed_blocks() {
  local file=$1
  awk -v begin="$BEGIN_MARK" -v end="$END_MARK" \
    -v legacy_begin="$LEGACY_BEGIN_MARK" -v legacy_end="$LEGACY_END_MARK" '
    {
      line = $0
      sub(/^[[:space:]]+/, "", line)
      if (!skip && (line == begin || line == legacy_begin)) { skip = 1; next }
      if (skip && (line == end || line == legacy_end)) { skip = 0; next }
      if (!skip) print
    }
  ' "$file"
}

# menu_block — the generated JSONC rows (without surrounding braces).
menu_block() {
  local name display primary cmd glyph icon_font action_cmd

  action_cmd=$(json_escape "$(shq "$OMARCHY_BROWSERS_BIN")")

  printf '%s\n' "$BEGIN_MARK"
  printf '%s\n' "// Generated from lib/browsers.tsv — run 'omarchy-browsers menu setup' to refresh."
  printf '%s\n' "// Anything between these markers is replaced; edit the registry instead."

  for name in "${BROWSER_NAMES[@]}"; do
    display=$(browser_display "$name")
    primary=$(browser_primary_package "$name")
    cmd=$(browser_command "$name")
    glyph=$(browser_menu_glyph "$name")
    icon_font=$(browser_icon_font "$name")

    if [[ -n $icon_font ]]; then
      printf '  "install.browser.%s": {"icon": "%s", "iconFont": "%s", "label": "%s", "when": "! omarchy-pkg-present %s", "action": "omarchy-launch-floating-terminal-with-presentation %s install %s"},\n' \
        "$name" "$(json_escape "$glyph")" "$(json_escape "$icon_font")" "$(json_escape "$display")" "$primary" "$action_cmd" "$name"
      printf '  "remove.browser.%s": {"icon": "%s", "iconFont": "%s", "label": "%s", "when": "omarchy-pkg-present %s", "action": "omarchy-launch-floating-terminal-with-presentation %s remove %s"},\n' \
        "$name" "$(json_escape "$glyph")" "$(json_escape "$icon_font")" "$(json_escape "$display")" "$primary" "$action_cmd" "$name"
      printf '  "setup.default.browser.%s": {"icon": "%s", "iconFont": "%s", "label": "%s", "when": "omarchy-cmd-present %s", "checked": "%s default %s --check", "action": "%s default %s"},\n' \
        "$name" "$(json_escape "$glyph")" "$(json_escape "$icon_font")" "$(json_escape "$display")" "$cmd" "$action_cmd" "$name" "$action_cmd" "$name"
    else
      printf '  "install.browser.%s": {"icon": "%s", "label": "%s", "when": "! omarchy-pkg-present %s", "action": "omarchy-launch-floating-terminal-with-presentation %s install %s"},\n' \
        "$name" "$(json_escape "$glyph")" "$(json_escape "$display")" "$primary" "$action_cmd" "$name"
      printf '  "remove.browser.%s": {"icon": "%s", "label": "%s", "when": "omarchy-pkg-present %s", "action": "omarchy-launch-floating-terminal-with-presentation %s remove %s"},\n' \
        "$name" "$(json_escape "$glyph")" "$(json_escape "$display")" "$primary" "$action_cmd" "$name"
      printf '  "setup.default.browser.%s": {"icon": "%s", "label": "%s", "when": "omarchy-cmd-present %s", "checked": "%s default %s --check", "action": "%s default %s"},\n' \
        "$name" "$(json_escape "$glyph")" "$(json_escape "$display")" "$cmd" "$action_cmd" "$name" "$action_cmd" "$name"
    fi
  done

  printf '%s\n' "$END_MARK"
}

# insert_block <base-file> <block-file> — insert the block before the final }.
insert_block() {
  local base=$1 block=$2
  awk -v block="$block" '
    { lines[NR] = $0 }
    END {
      last = 0
      for (i = NR; i >= 1; i--) {
        if (lines[i] ~ /^[[:space:]]*}[[:space:]]*$/) { last = i; break }
      }
      if (last == 0) {
        print "error: menu file has no closing brace" > "/dev/stderr"
        exit 1
      }

      # The last real key before the closing brace needs a trailing comma,
      # otherwise our block would be glued onto it and the file would stop
      # parsing. Blank lines and // comments do not count as keys.
      sig = 0
      for (i = last - 1; i >= 1; i--) {
        t = lines[i]
        sub(/^[[:space:]]+/, "", t)
        if (t == "" || t ~ /^\/\//) continue
        sig = i
        break
      }

      for (i = 1; i < last; i++) {
        if (i == sig && lines[i] !~ /[,{\[][[:space:]]*$/) print lines[i] ","
        else print lines[i]
      }
      while ((getline line < block) > 0) print line
      for (i = last; i <= NR; i++) print lines[i]
    }
  ' "$base"
}

# validate_menu <file> — parse the merged menu with Omarchy's own parser.
# Returns 0 (skip) when node or MenuModel.js are unavailable.
validate_menu() {
  local file=$1

  if ! command -v node >/dev/null 2>&1 || [[ ! -f $MENU_MODEL ]]; then
    warn "node or MenuModel.js not available — skipping JSONC validation."
    return 0
  fi

  local expected='' expected_font=''
  local name family
  for name in "${BROWSER_NAMES[@]}"; do
    expected+="${expected:+,}\"install.browser.$name\",\"remove.browser.$name\",\"setup.default.browser.$name\""
    family=$(browser_icon_font "$name")
    if [[ -n $family ]]; then
      expected_font+="${expected_font:+,}\"install.browser.$name\",\"remove.browser.$name\",\"setup.default.browser.$name\""
    fi
  done

  MENU_FILE="$file" \
    MENU_MODEL="$MENU_MODEL" \
    DEFAULT_MENU_FILE="$DEFAULT_MENU_FILE" \
    EXPECTED_IDS="[$expected]" \
    EXPECTED_FONT_IDS="[$expected_font]" \
    node -e '
      const fs = require("fs");
      const model = require(process.env.MENU_MODEL);
      const read = (p) => fs.existsSync(p) ? model.parseMenuJsonc(fs.readFileSync(p, "utf8")) : [];
      const user = read(process.env.MENU_FILE);
      const base = read(process.env.DEFAULT_MENU_FILE);
      const merged = model.mergeMenuSources(base, user);
      const expected = JSON.parse(process.env.EXPECTED_IDS);
      const missing = expected.filter((id) => !merged.items[id]);
      if (missing.length) {
        console.error("menu validation failed — missing rows: " + missing.join(", "));
        process.exit(1);
      }
      const iconless = expected.filter((id) => !merged.items[id].icon);
      if (iconless.length) {
        console.error("menu validation failed — rows lost their icon: " + iconless.join(", "));
        process.exit(1);
      }
      const fontless = JSON.parse(process.env.EXPECTED_FONT_IDS)
        .filter((id) => !merged.items[id].iconFont);
      if (fontless.length) {
        console.error("menu validation failed — rows lost their iconFont: " + fontless.join(", "));
        process.exit(1);
      }
      process.stdout.write("validated " + expected.length + " browser rows\n");
    '
}

# menu_write <content-file> — atomically replace MENU_FILE when it differs.
menu_write() {
  local content=$1 target_dir tmp
  target_dir=$(dirname "$MENU_FILE")
  tmp=$(mktemp "$target_dir/.omarchy-menu.XXXXXX")
  cp -- "$content" "$tmp"

  if [[ -f $MENU_FILE ]] && cmp -s "$tmp" "$MENU_FILE"; then
    rm -f -- "$tmp"
    return 1 # unchanged
  fi

  chmod 0644 "$tmp"
  mv -f -- "$tmp" "$MENU_FILE"
  return 0
}

menu_prepare_file() {
  [[ -n ${DRY_RUN:-} ]] && return 0

  local dir
  dir=$(dirname "$MENU_FILE")
  mkdir -p -- "$dir"

  if [[ ! -f $MENU_FILE ]]; then
    printf '{\n}\n' >"$MENU_FILE"
    return 0
  fi

  if [[ ! -s $MENU_FILE ]]; then
    printf '{\n}\n' >"$MENU_FILE"
    return 0
  fi

  # Normalize the compact `{}` form so the block can be inserted before `}`.
  if [[ $(tr -d '[:space:]' <"$MENU_FILE") == '{}' ]]; then
    printf '{\n}\n' >"$MENU_FILE"
  fi
}

# ---------------------------------------------------------------------------
# Public commands
# ---------------------------------------------------------------------------

menu_setup() {
  local work base block content

  menu_prepare_file
  menu_install_fonts
  menu_prune_legacy_fonts

  if [[ -z ${DRY_RUN:-} ]]; then
    work=$(mktemp -d)
    base="$work/base.jsonc"
    block="$work/block.jsonc"
    content="$work/menu.jsonc"

    strip_managed_blocks "$MENU_FILE" >"$base"
    menu_block >"$block"

    if ! insert_block "$base" "$block" >"$content"; then
      rm -rf -- "$work"
      die "could not insert the managed block into $MENU_FILE"
    fi

    if ! validate_menu "$content" >/dev/null; then
      rm -rf -- "$work"
      die "generated menu block is invalid — $MENU_FILE was left untouched"
    fi

    if menu_write "$content"; then
      ok "menu rows written: $MENU_FILE"
    else
      info "menu rows already up to date: $MENU_FILE"
    fi
    rm -rf -- "$work"
  else
    info "would write the managed block to $MENU_FILE"
  fi

  echo
  ok "$(( ${#BROWSER_NAMES[@]} * 3 )) menu rows ready — ${#BROWSER_NAMES[@]} browsers × install / remove / default"
  echo "Open the menu with Super+X — it rereads this file, so the rows show up immediately."
}

menu_teardown() {
  local work content changed=0

  if [[ ! -f $MENU_FILE ]]; then
    info "no menu file at $MENU_FILE — nothing to do."
    menu_remove_fonts
    menu_prune_legacy_fonts
    return 0
  fi

  if menu_file_exists_integration || grep -qF "$LEGACY_BEGIN_MARK" "$MENU_FILE"; then
    if [[ -n ${DRY_RUN:-} ]]; then
      info "would remove the managed block from $MENU_FILE"
    else
      work=$(mktemp -d)
      content="$work/menu.jsonc"
      strip_managed_blocks "$MENU_FILE" >"$content"
      if menu_write "$content"; then
        changed=1
      fi
      rm -rf -- "$work"
    fi
  fi

  menu_remove_fonts
  menu_prune_legacy_fonts

  if (( changed )); then
    ok "removed the managed rows from $MENU_FILE"
  else
    info "no managed rows found in $MENU_FILE"
  fi
  echo "Installed browsers were not touched."
}

menu_status() {
  local rows=0

  echo "menu file:   $MENU_FILE"
  echo "registry:    $REGISTRY_FILE"
  echo "dispatcher:  $OMARCHY_BROWSERS_BIN"

  if [[ -f $MENU_FILE ]] && grep -qF "$BEGIN_MARK" "$MENU_FILE"; then
    rows=$(grep -cE '"(install|remove)\.browser\.|"setup\.default\.browser\.' "$MENU_FILE" || true)
    ok "managed block present ($rows rows)"
  else
    warn "managed block not installed — run 'omarchy-browsers menu setup'"
  fi

  local family
  while IFS= read -r family; do
    [[ -n $family ]] || continue
    if menu_font_installed "$family"; then
      ok "icon font installed: $family"
    else
      warn "icon font missing: $family (run 'omarchy-browsers menu setup')"
    fi
  done < <(menu_icon_fonts)

  if [[ -f $MENU_FILE ]]; then
    validate_menu "$MENU_FILE" || true
  fi
}
