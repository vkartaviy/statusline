#!/usr/bin/env bash
# directory.sh — current directory relative to project, smart collapse

# Check if a directory has multiple subdirectories
_has_siblings() {
  local dir="$1"
  [ -d "$dir" ] || return 1
  # Temporarily enable globbing (statusline.sh uses set -f)
  set +f
  local count=0 entry
  for entry in "$dir"/*/; do
    [ -d "$entry" ] || continue
    count=$((count + 1))
    [ "$count" -gt 1 ] && { set -f; return 0; }
  done
  set -f
  return 1
}

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

  local display="$rel"
  local max_len=30

  # Only collapse if path is too long
  if [ ${#display} -gt "$max_len" ]; then
    # Count components
    local count=1 tmp="$rel"
    while [ "${tmp#*/}" != "$tmp" ]; do
      count=$((count + 1))
      tmp="${tmp#*/}"
    done

    if [ "$count" -gt 2 ]; then
      local last="${rel##*/}"
      local rest="${rel%/*}"
      local first="${rest%%/*}"
      local second="${rest#*/}"
      second="${second%%/*}"

      # Check siblings at each level to decide where to collapse
      # If a level has siblings → keep it (disambiguation needed)
      local third="${rest#*/}"  # strip first
      third="${third#*/}"       # strip second
      third="${third%%/*}"      # get third component

      if [ -n "$project" ] && [ -n "$third" ] && \
         _has_siblings "${project}/${first}"; then
        # 3rd level has siblings → keep first 3 + last 1
        display="${first}/${second}/${third}/…/${last}"
        # If 3rd == last, no need for …
        [ "$third" = "$last" ] && display="${first}/${second}/${third}"
      else
        # No siblings → safe to collapse after first 2
        display="${first}/${second}/…/${last}"
      fi
    fi
  fi

  printf '%b%s%s%b' "$_THEME_DIR" "$_ICON_DIR" "$display" "$_CLR_RESET"
}
