#!/usr/bin/env bash
# rate_limits.sh — API rate limit usage (4 sub-styles)

# Color by percentage threshold
_rate_color() {
  local pct="$1"
  if [ "$pct" -lt 50 ]; then
    printf '%s' "$_THEME_RATE_OK"
  elif [ "$pct" -lt 80 ]; then
    printf '%s' "$_THEME_RATE_WARN"
  else
    printf '%s' "$_THEME_RATE_CRIT"
  fi
}

# Format countdown from epoch to human-readable
_rate_countdown() {
  local resets_at="$1"
  [ "$resets_at" -le 0 ] && return 1

  local now
  now=$(date +%s)
  local remaining=$((resets_at - now))
  [ "$remaining" -le 0 ] && { printf '0m'; return; }

  local days=$((remaining / 86400))
  local hours=$(((remaining % 86400) / 3600))
  local mins=$(((remaining % 3600) / 60))

  if [ "$days" -gt 0 ]; then
    printf '%dd' "$days"
  elif [ "$hours" -gt 0 ]; then
    printf '%dh%02dm' "$hours" "$mins"
  else
    printf '%dm' "$mins"
  fi
}

# Build a small bar (8 chars wide) for bar style
_rate_bar() {
  local pct="$1"
  local width=8
  local filled=$((pct * width / 100))
  local empty=$((width - filled))

  local color
  color=$(_rate_color "$pct")

  local bar=""
  local i
  for ((i=0; i<filled; i++)); do
    bar="${bar}${_CFG_BAR_FILLED}"
  done
  local empty_part=""
  for ((i=0; i<empty; i++)); do
    empty_part="${empty_part}${_CFG_BAR_EMPTY}"
  done

  printf '%b%s%b%s%b' "$color" "$bar" "$_THEME_BAR_EMPTY" "$empty_part" "$_CLR_RESET"
}

segment_rate_limits() {
  # Need at least one rate limit present
  local h5="${_CC_RATE_5H:--1}"
  local d7="${_CC_RATE_7D:--1}"
  [ "$h5" = "-1" ] && [ "$d7" = "-1" ] && return 1

  # Truncate to integer for display and comparison
  local h5_int="${h5%.*}"
  local d7_int="${d7%.*}"

  case "$_CFG_RATE_STYLE" in
    compact)
      local parts=""
      if [ "$h5_int" -ge 0 ]; then
        local c5; c5=$(_rate_color "$h5_int")
        parts=$(printf '%b5h:%d%%%b' "$c5" "$h5_int" "$_CLR_RESET")
      fi
      if [ "$d7_int" -ge 0 ]; then
        local c7; c7=$(_rate_color "$d7_int")
        [ -n "$parts" ] && parts="${parts}$(printf ' %b·%b ' "$_THEME_LABEL" "$_CLR_RESET")"
        parts="${parts}$(printf '%b7d:%d%%%b' "$c7" "$d7_int" "$_CLR_RESET")"
      fi
      printf '%s' "$parts"
      ;;

    bar)
      local parts=""
      if [ "$h5_int" -ge 0 ]; then
        parts=$(printf '%b5h%b %s' "$_THEME_LABEL" "$_CLR_RESET" "$(_rate_bar "$h5_int")")
      fi
      if [ "$d7_int" -ge 0 ]; then
        [ -n "$parts" ] && parts="${parts} "
        parts="${parts}$(printf '%b7d%b %s' "$_THEME_LABEL" "$_CLR_RESET" "$(_rate_bar "$d7_int")")"
      fi
      printf '%s' "$parts"
      ;;

    dot)
      # Single dot colored by worst (highest) percentage
      local worst=0
      [ "$h5_int" -gt "$worst" ] && worst="$h5_int"
      [ "$d7_int" -gt "$worst" ] && worst="$d7_int"
      local color
      color=$(_rate_color "$worst")
      printf '%b●%b' "$color" "$_CLR_RESET"
      ;;

    full)
      local parts=""
      if [ "$h5_int" -ge 0 ]; then
        local c5; c5=$(_rate_color "$h5_int")
        parts=$(printf '%b5h:%d%%%b' "$c5" "$h5_int" "$_CLR_RESET")
        local cd5
        if cd5=$(_rate_countdown "$_CC_RATE_5H_RESET"); then
          parts="${parts}$(printf ' %b⟳%s%b' "$_THEME_LABEL" "$cd5" "$_CLR_RESET")"
        fi
      fi
      if [ "$d7_int" -ge 0 ]; then
        local c7; c7=$(_rate_color "$d7_int")
        [ -n "$parts" ] && parts="${parts}$(printf ' %b·%b ' "$_THEME_LABEL" "$_CLR_RESET")"
        parts="${parts}$(printf '%b7d:%d%%%b' "$c7" "$d7_int" "$_CLR_RESET")"
        local cd7
        if cd7=$(_rate_countdown "$_CC_RATE_7D_RESET"); then
          parts="${parts}$(printf ' %b⟳%s%b' "$_THEME_LABEL" "$cd7" "$_CLR_RESET")"
        fi
      fi
      printf '%s' "$parts"
      ;;
  esac
}
