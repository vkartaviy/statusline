#!/usr/bin/env bash
# context_bar.sh — context window usage bar with gradient colors

segment_context_bar() {
  # Need context window size to compute percentage
  [ "${_CC_CTX_SIZE:-0}" -eq 0 ] && return 1

  local total_tokens=$((_CC_INPUT_TOKENS + _CC_CACHE_CREATE + _CC_CACHE_READ))
  local pct=$((total_tokens * 100 / _CC_CTX_SIZE))

  # Clamp to 0-100
  [ "$pct" -lt 0 ] && pct=0
  [ "$pct" -gt 100 ] && pct=100

  # Select gradient color based on threshold
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

  # Build bar
  local filled=$((pct * _CFG_BAR_WIDTH / 100))
  local empty=$((_CFG_BAR_WIDTH - filled))

  local bar=""
  local i
  for ((i=0; i<filled; i++)); do
    bar="${bar}${_CFG_BAR_FILLED}"
  done

  local empty_part=""
  for ((i=0; i<empty; i++)); do
    empty_part="${empty_part}${_CFG_BAR_EMPTY}"
  done

  printf '%b%s%b%s%b %b%d%%%b' \
    "$color" "$bar" \
    "$_THEME_BAR_EMPTY" "$empty_part" "$_CLR_RESET" \
    "$color" "$pct" "$_CLR_RESET"
}
