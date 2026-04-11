#!/usr/bin/env bash
# colors.sh — ANSI reset constant and no-color support

# Reset all formatting
_CLR_RESET="\033[0m"

# Strip all color if requested
cc_disable_colors() {
  _CLR_RESET=""
  # Wipe every _THEME_* variable so segments emit plain text
  local var
  for var in $(compgen -v _THEME_ 2>/dev/null); do
    eval "$var=''"
  done
}
