#!/usr/bin/env bash
# directory.sh — current directory relative to project, collapsed if deep/long

segment_directory() {
  [ -z "$_CC_CWD" ] && return 1

  local project="${_CC_PROJECT_DIR:-}"
  local cwd="$_CC_CWD"

  # Compute relative path from project
  local rel=""
  if [ -n "$project" ] && [ "$cwd" != "$project" ]; then
    case "$cwd" in
      "${project}/"*) rel="${cwd#${project}/}" ;;
      *) rel="$cwd" ;;
    esac
  fi

  # In project root — hide (project segment handles it)
  [ -z "$rel" ] && return 1

  # Count path components
  local count=1 tmp="$rel"
  while [ "${tmp#*/}" != "$tmp" ]; do
    count=$((count + 1))
    tmp="${tmp#*/}"
  done

  local display="$rel"
  local max_len=25

  # Collapse: always keep first 2 + last 1
  if [ "$count" -gt 3 ]; then
    local last="${rel##*/}"
    local rest="${rel%/*}"
    local first="${rest%%/*}"
    local second="${rest#*/}"
    second="${second%%/*}"

    display="${first}/${second}/…/${last}"
  fi

  printf '%b%s%s%b' "$_THEME_DIR" "$_ICON_DIR" "$display" "$_CLR_RESET"
}
