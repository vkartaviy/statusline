#!/usr/bin/env bash
# cost.sh — session cost in USD

segment_cost() {
  # Skip if cost is 0 or empty
  [ -z "$_CC_COST" ] && return 1
  [ "$_CC_COST" = "0" ] && return 1

  printf '%b%s$%s%b' "$_THEME_COST" "$_ICON_COST" "$_CC_COST" "$_CLR_RESET"
}
