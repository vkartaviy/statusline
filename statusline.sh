#!/usr/bin/env bash
# statusline.sh — configurable statusline for Claude Code
# Reads JSON from stdin, outputs formatted statusline.

set -f  # disable globbing (not needed, avoid surprises)

# Resolve script directory (works through symlinks)
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Load core libraries ──
. "${_SCRIPT_DIR}/lib/colors.sh"
. "${_SCRIPT_DIR}/lib/config.sh"
. "${_SCRIPT_DIR}/lib/help.sh"
. "${_SCRIPT_DIR}/lib/parse.sh"
. "${_SCRIPT_DIR}/lib/render.sh"

# ── Configure ──
cc_load_config "$@"

# ── Help early exit ──
if [ "$_CFG_SHOW_HELP" -eq 1 ]; then
  cc_show_help
  exit 0
fi

# ── Load theme ──
_theme_file="${_SCRIPT_DIR}/themes/${_CFG_THEME}.sh"
if [ -f "$_theme_file" ]; then
  . "$_theme_file"
else
  . "${_SCRIPT_DIR}/themes/default.sh"
fi

# ── Disable colors if requested (after theme load) ──
if [ "$_CFG_NO_COLOR" -eq 1 ]; then
  cc_disable_colors
fi

# ── Parse input ──
cc_parse_input || exit 0

# ── Render ──
cc_render
