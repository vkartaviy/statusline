#!/usr/bin/env bash
# vim_mode.sh — vim mode indicator (NORMAL/INSERT)

segment_vim_mode() {
  [ -z "$_CC_VIM_MODE" ] && return 1

  local color
  case "$_CC_VIM_MODE" in
    NORMAL) color="$_THEME_VIM_N" ;;
    INSERT) color="$_THEME_VIM_I" ;;
    *)      color="$_THEME_VIM_N" ;;
  esac

  printf '%b%s%b' "$color" "$_CC_VIM_MODE" "$_CLR_RESET"
}
