#!/usr/bin/env bash
# cost.sh — session cost in USD

segment_cost() {
  # Skip if cost is 0 or empty
  [ -z "$_CC_COST" ] && return 1
  [ "$_CC_COST" = "0" ] && return 1

  # Ensure two decimal places (jq drops trailing zeros)
  local formatted
  case "$_CC_COST" in
    *.*.*) formatted="$_CC_COST" ;;  # shouldn't happen
    *.*)
      local decimals="${_CC_COST#*.}"
      if [ ${#decimals} -lt 2 ]; then
        formatted="${_CC_COST}0"
      else
        formatted="$_CC_COST"
      fi
      ;;
    *) formatted="${_CC_COST}.00" ;;
  esac

  printf '%b%s$%s%b' "$_THEME_COST" "$_ICON_COST" "$formatted" "$_CLR_RESET"
}
