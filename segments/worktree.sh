#!/usr/bin/env bash
# worktree.sh — git worktree name

segment_worktree() {
  [ -z "$_CC_WORKTREE" ] && return 1

  local icon=""
  [ "$_CFG_ICONS" -eq 1 ] && icon=" "

  printf '%b%s%s%b' "$_THEME_WORKTREE" "$icon" "$_CC_WORKTREE" "$_CLR_RESET"
}
