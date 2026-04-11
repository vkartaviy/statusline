#!/usr/bin/env bash
# default.sh — green→yellow→red gradient theme

_THEME_BAR_LOW="\033[2;32m"      # dim green  (0-50%)
_THEME_BAR_MED="\033[2;33m"      # dim yellow (50-70%)
_THEME_BAR_HIGH="\033[2;31m"     # dim red    (70-80%)
_THEME_BAR_CRIT="\033[0;31m"     # bright red (80-100%)
_THEME_BAR_EMPTY="\033[2;37m"    # dim white
_THEME_PCT="\033[2;37m"          # dim white
_THEME_DIR="\033[0;37m"          # white
_THEME_MODEL="\033[0;36m"        # cyan
_THEME_COST="\033[0;33m"         # yellow
_THEME_RATE_OK="\033[0;32m"      # green
_THEME_RATE_WARN="\033[0;33m"    # yellow
_THEME_RATE_CRIT="\033[0;31m"    # red
_THEME_VIM_N="\033[0;32m"        # green (NORMAL)
_THEME_VIM_I="\033[0;34m"        # blue (INSERT)
_THEME_WORKTREE="\033[0;35m"     # magenta
_THEME_LINES_ADD="\033[0;32m"    # green
_THEME_LINES_DEL="\033[0;31m"    # red
_THEME_TIME="\033[2;37m"         # dim white
_THEME_SEP="\033[2;37m"          # dim white
_THEME_LABEL="\033[2;37m"        # dim white
