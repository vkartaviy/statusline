#!/usr/bin/env bash
# rate_limits.sh — API rate limit usage (4 sub-styles)

# Compute projected usage at end of window (pace-based)
# Returns projected percentage (0-999, clamped)
_rate_pace() {
  local used_pct="$1"
  local resets_at="$2"
  local window="$3"  # window size in seconds (5h=18000, 7d=604800)

  # Can't compute pace without reset time
  if [ "$resets_at" -le 0 ]; then
    printf '%d' "$used_pct"
    return
  fi

  local remaining=$((_RATE_NOW - resets_at))
  # remaining is negative (resets_at is in the future)
  remaining=$((resets_at - _RATE_NOW))
  [ "$remaining" -le 0 ] && { printf '%d' "$used_pct"; return; }

  local elapsed=$((window - remaining))
  # Just started or no time elapsed — can't project
  if [ "$elapsed" -le 0 ]; then
    printf '%d' "$used_pct"
    return
  fi

  # projected = used_pct * window / elapsed
  # Use bigger multiplier to avoid integer truncation
  local projected=$((used_pct * window / elapsed))
  [ "$projected" -gt 100 ] && projected=100

  printf '%d' "$projected"
}

# Color by pace (projected usage at end of window)
_rate_color() {
  local pct="$1"
  if [ "$pct" -lt 70 ]; then
    printf '%s' "$_THEME_RATE_OK"
  elif [ "$pct" -lt 90 ]; then
    printf '%s' "$_THEME_RATE_WARN"
  else
    printf '%s' "$_THEME_RATE_CRIT"
  fi
}

# Format countdown from epoch to human-readable
_rate_countdown() {
  local resets_at="$1"
  [ "$resets_at" -le 0 ] && return 1

  local remaining=$((resets_at - _RATE_NOW))
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

# Build a 3-zone bar (8 chars wide) showing remaining capacity + pace
# Zone 1 (filled): safe — will remain even at current pace
# Zone 2 (pace):   at risk — projected to be consumed at current pace
# Zone 3 (empty):  already used
_rate_bar() {
  local used_pct="$1"
  local pace="${2:-$used_pct}"  # projected usage at end of window
  local width=8

  # Remaining blocks (current)
  local remain=$((100 - used_pct))
  [ "$remain" -lt 0 ] && remain=0

  # Projected remaining at end of window
  local proj_remain=$((100 - pace))
  [ "$proj_remain" -lt 0 ] && proj_remain=0
  [ "$proj_remain" -gt "$remain" ] && proj_remain="$remain"

  # Three zones in blocks
  local safe_blocks=$((proj_remain * width / 100))
  local total_remain_blocks=$((remain * width / 100))
  local pace_blocks=$((total_remain_blocks - safe_blocks))
  local used_blocks=$((width - total_remain_blocks))

  local color
  color=$(_rate_color "$pace")

  local bar="" i
  for ((i=0; i<safe_blocks; i++)); do
    bar="${bar}${_CFG_BAR_FILLED}"
  done

  local pace_part=""
  for ((i=0; i<pace_blocks; i++)); do
    pace_part="${pace_part}${_CFG_BAR_PACE}"
  done

  local empty_part=""
  for ((i=0; i<used_blocks; i++)); do
    empty_part="${empty_part}${_CFG_BAR_EMPTY}"
  done

  printf '%b%s%b%s%b%s%b %b%d%%%b' \
    "$color" "$bar" \
    "$_THEME_BAR_MED" "$pace_part" \
    "$_THEME_BAR_EMPTY" "$empty_part" "$_CLR_RESET" \
    "$color" "$remain" "$_CLR_RESET"
}

segment_rate_limits() {
  # Need at least one rate limit present
  local h5="${_CC_RATE_5H:--1}"
  local d7="${_CC_RATE_7D:--1}"
  [ "$h5" = "-1" ] && [ "$d7" = "-1" ] && return 1

  # Single date call for the whole segment
  _RATE_NOW=$(date +%s)

  # Truncate to integer for display and comparison
  local h5_int="${h5%.*}"
  local d7_int="${d7%.*}"

  # Compute pace (projected usage at end of window)
  local h5_pace d7_pace
  h5_pace=$(_rate_pace "$h5_int" "${_CC_RATE_5H_RESET:--1}" 18000)   # 5h = 18000s
  d7_pace=$(_rate_pace "$d7_int" "${_CC_RATE_7D_RESET:--1}" 604800)  # 7d = 604800s

  case "$_CFG_RATE_STYLE" in
    compact)
      local parts=""
      if [ "$h5_int" -ge 0 ]; then
        local c5; c5=$(_rate_color "$h5_pace")
        parts=$(printf '%b5h:%d%%%b' "$c5" "$h5_int" "$_CLR_RESET")
      fi
      if [ "$d7_int" -ge 0 ]; then
        local c7; c7=$(_rate_color "$d7_pace")
        [ -n "$parts" ] && parts="${parts}$(printf ' %b·%b ' "$_THEME_LABEL" "$_CLR_RESET")"
        parts="${parts}$(printf '%b7d:%d%%%b' "$c7" "$d7_int" "$_CLR_RESET")"
      fi
      printf '%s' "$parts"
      ;;

    dot)
      # Single dot colored by worst pace
      local worst=0
      [ "$h5_pace" -gt "$worst" ] && worst="$h5_pace"
      [ "$d7_pace" -gt "$worst" ] && worst="$d7_pace"
      local color
      color=$(_rate_color "$worst")
      printf '%b●%b' "$color" "$_CLR_RESET"
      ;;

    full)
      # Bar (remaining) + % + countdown, colored by pace
      local parts=""
      if [ "$h5_int" -ge 0 ]; then
        parts=$(printf '%b5h%b %s' "$_THEME_LABEL" "$_CLR_RESET" "$(_rate_bar "$h5_int" "$h5_pace")")
        local cd5
        if cd5=$(_rate_countdown "$_CC_RATE_5H_RESET"); then
          parts="${parts}$(printf ' %b%s%s%b' "$_THEME_LABEL" "$_ICON_RESET" "$cd5" "$_CLR_RESET")"
        fi
      fi
      if [ "$d7_int" -ge 0 ]; then
        [ -n "$parts" ] && parts="${parts}$(printf ' %b·%b ' "$_THEME_LABEL" "$_CLR_RESET")"
        parts="${parts}$(printf '%b7d%b %s' "$_THEME_LABEL" "$_CLR_RESET" "$(_rate_bar "$d7_int" "$d7_pace")")"
        local cd7
        if cd7=$(_rate_countdown "$_CC_RATE_7D_RESET"); then
          parts="${parts}$(printf ' %b%s%s%b' "$_THEME_LABEL" "$_ICON_RESET" "$cd7" "$_CLR_RESET")"
        fi
      fi
      printf '%s' "$parts"
      ;;
  esac
}
