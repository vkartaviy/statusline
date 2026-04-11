#!/usr/bin/env bash
# context_pct.sh — context window percentage (number only)

segment_context_pct() {
  [ "${_CC_CTX_SIZE:-0}" -eq 0 ] && return 1

  local total_tokens=$((_CC_INPUT_TOKENS + _CC_CACHE_CREATE + _CC_CACHE_READ))
  local pct=$((total_tokens * 100 / _CC_CTX_SIZE))

  [ "$pct" -lt 0 ] && pct=0
  [ "$pct" -gt 100 ] && pct=100

  # Color by threshold (same as bar)
  local color
  if [ "$pct" -lt 50 ]; then
    color="$_THEME_BAR_LOW"
  elif [ "$pct" -lt 70 ]; then
    color="$_THEME_BAR_MED"
  elif [ "$pct" -lt 80 ]; then
    color="$_THEME_BAR_HIGH"
  else
    color="$_THEME_BAR_CRIT"
  fi

  printf '%b%d%%%b' "$color" "$pct" "$_CLR_RESET"
}
