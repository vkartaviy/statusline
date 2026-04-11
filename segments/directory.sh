#!/usr/bin/env bash
# directory.sh — project directory (last 2 path components)

segment_directory() {
  [ -z "$_CC_CWD" ] && return 1

  local dir="$_CC_CWD"
  # Extract last two path components using parameter expansion
  local base="${dir##*/}"
  local parent_path="${dir%/*}"
  local parent="${parent_path##*/}"

  local display
  if [ -n "$parent" ] && [ "$parent" != "$base" ]; then
    display="${parent}/${base}"
  else
    display="$base"
  fi

  printf '%b%s%s%b' "$_THEME_DIR" "$_ICON_DIR" "$display" "$_CLR_RESET"
}
