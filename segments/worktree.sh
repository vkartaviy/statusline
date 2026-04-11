#!/usr/bin/env bash
# worktree.sh — git worktree name

segment_worktree() {
  [ -z "$_CC_WORKTREE" ] && return 1

  printf '%b%s%s%b' "$_THEME_WORKTREE" "$_ICON_WORKTREE" "$_CC_WORKTREE" "$_CLR_RESET"
}
