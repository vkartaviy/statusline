#!/usr/bin/env bash
# model.sh — model display name

segment_model() {
  [ -z "$_CC_MODEL" ] && return 1

  local icon=""
  [ "$_CFG_ICONS" -eq 1 ] && icon=" "

  printf '%b%s%s%b' "$_THEME_MODEL" "$icon" "$_CC_MODEL" "$_CLR_RESET"
}
