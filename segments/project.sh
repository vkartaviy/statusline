#!/usr/bin/env bash
# project.sh — project root name

segment_project() {
  local dir="${_CC_PROJECT_DIR:-$_CC_CWD}"
  [ -z "$dir" ] && return 1

  local name="${dir##*/}"

  local icon=""
  [ -n "$_ICON_PROJECT" ] && icon="$_ICON_PROJECT"

  printf '%b%s%s%b' "$_THEME_DIR" "$icon" "$name" "$_CLR_RESET"
}
