#!/usr/bin/env bash
# directory.sh — current directory relative to project, collapsed if deep

segment_directory() {
  [ -z "$_CC_CWD" ] && return 1

  local project="${_CC_PROJECT_DIR:-}"
  local cwd="$_CC_CWD"

  # Compute relative path from project
  local rel=""
  if [ -n "$project" ] && [ "$cwd" != "$project" ]; then
    # Strip project prefix to get relative path
    case "$cwd" in
      "${project}/"*) rel="${cwd#${project}/}" ;;
      *) rel="$cwd" ;;  # outside project — show as-is
    esac
  fi

  # In project root — hide (project segment handles it)
  [ -z "$rel" ] && return 1

  # Collapse if more than 3 components
  local count=1 tmp="$rel"
  while [ "${tmp#*/}" != "$tmp" ]; do
    count=$((count + 1))
    tmp="${tmp#*/}"
  done

  local display
  if [ "$count" -le 3 ]; then
    display="$rel"
  else
    local first="${rel%%/*}"
    local last="${rel##*/}"
    display="${first}/…/${last}"
  fi

  printf '%b%s%s%b' "$_THEME_DIR" "$_ICON_DIR" "$display" "$_CLR_RESET"
}
