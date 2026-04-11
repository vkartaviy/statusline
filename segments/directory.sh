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

  # Collapse: keep first 2 + last 1, skip middle
  if [ "$count" -gt 3 ] || [ ${#display} -gt "$max_len" ]; then
    local last="${rel##*/}"
    local rest="${rel%/*}"        # strip last
    local first="${rest%%/*}"     # first component
    local second_rest="${rest#*/}"
    local second="${second_rest%%/*}"  # second component

    if [ "$first" != "$second" ] && [ "$count" -gt 2 ]; then
      display="${first}/${second}/…/${last}"
    else
      display="${first}/…/${last}"
    fi

    # If still too long, drop to first/…/last
    if [ ${#display} -gt "$max_len" ]; then
      display="${first}/…/${last}"
    fi
  fi

  printf '%b%s%s%b' "$_THEME_DIR" "$_ICON_DIR" "$display" "$_CLR_RESET"
}
