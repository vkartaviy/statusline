#!/usr/bin/env bash
# model.sh — model display name

segment_model() {
  [ -z "$_CC_MODEL" ] && return 1

  printf '%b%s%s%b' "$_THEME_MODEL" "$_ICON_MODEL" "$_CC_MODEL" "$_CLR_RESET"
}
