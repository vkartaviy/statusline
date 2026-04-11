#!/usr/bin/env bash
# lines_changed.sh — lines added/removed (+N -M)

segment_lines_changed() {
  # Skip if both are 0 or empty
  local added="${_CC_LINES_ADDED:-0}"
  local removed="${_CC_LINES_REMOVED:-0}"
  [ "$added" -eq 0 ] && [ "$removed" -eq 0 ] && return 1

  local result=""
  if [ "$added" -gt 0 ]; then
    result=$(printf '%b+%d%b' "$_THEME_LINES_ADD" "$added" "$_CLR_RESET")
  fi
  if [ "$removed" -gt 0 ]; then
    [ -n "$result" ] && result="${result} "
    result="${result}$(printf '%b-%d%b' "$_THEME_LINES_DEL" "$removed" "$_CLR_RESET")"
  fi

  printf '%s' "$result"
}
