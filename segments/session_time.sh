#!/usr/bin/env bash
# session_time.sh — session duration (ms → Xm Ys)

segment_session_time() {
  [ -z "$_CC_DURATION_MS" ] && return 1
  [ "$_CC_DURATION_MS" = "0" ] && return 1

  local total_sec=$((_CC_DURATION_MS / 1000))
  local hours=$((total_sec / 3600))
  local mins=$(((total_sec % 3600) / 60))
  local secs=$((total_sec % 60))

  local display=""
  if [ "$hours" -gt 0 ]; then
    display="${hours}h ${mins}m"
  elif [ "$mins" -gt 0 ]; then
    display="${mins}m ${secs}s"
  else
    display="${secs}s"
  fi

  local icon=""
  [ "$_CFG_ICONS" -eq 1 ] && icon=" "

  printf '%b%s%s%b' "$_THEME_TIME" "$icon" "$display" "$_CLR_RESET"
}
