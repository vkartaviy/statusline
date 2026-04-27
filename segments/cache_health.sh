#!/usr/bin/env bash
# cache_health.sh — prompt cache hit ratio + thrash detection
#
# Tracks cache_read vs cache_creation across refreshes within a session.
# When read tokens stay at 0 while creation is high, the cache is being
# rebuilt every turn (you're paying full input price instead of the ~90%
# cached discount). Per-session state lives in $TMPDIR/claude-statusline/.

segment_cache_health() {
  [ -z "${_CC_SESSION_ID:-}" ] && return 1

  local cache_read="${_CC_CACHE_READ:-0}"
  local cache_create="${_CC_CACHE_CREATE:-0}"
  local total=$((cache_read + cache_create))
  [ "$total" -le 0 ] && return 1

  local state_dir="${TMPDIR:-/tmp}/claude-statusline"
  local state_file="${state_dir}/${_CC_SESSION_ID}.cache"
  mkdir -p "$state_dir" 2>/dev/null

  local checks=0 zero_reads=0
  if [ -f "$state_file" ]; then
    read -r checks zero_reads < "$state_file" 2>/dev/null
  fi
  case "$checks"     in *[!0-9]*|'') checks=0 ;; esac
  case "$zero_reads" in *[!0-9]*|'') zero_reads=0 ;; esac

  checks=$((checks + 1))
  if [ "$cache_read" -eq 0 ] && [ "$cache_create" -gt 0 ]; then
    zero_reads=$((zero_reads + 1))
  else
    zero_reads=0
  fi
  printf '%d %d\n' "$checks" "$zero_reads" > "$state_file" 2>/dev/null

  # When no icon is available (--icons none), use a text label to
  # disambiguate from context_pct.
  local prefix="${_ICON_CACHE:-cache:}"

  # Sustained zero reads → cache is being rebuilt every turn.
  if [ "$checks" -gt 2 ] && [ "$zero_reads" -ge 3 ]; then
    printf '%b%smiss%b' "$_THEME_RATE_CRIT" "$prefix" "$_CLR_RESET"
    return 0
  fi

  # Cold-start: first refreshes have nothing to read yet — suppress
  # alarming 0% before the cache has been built.
  if [ "$checks" -le 2 ] && [ "$cache_read" -eq 0 ]; then
    return 1
  fi

  local pct=$((cache_read * 100 / total))
  local color
  if [ "$pct" -gt 80 ]; then
    color="$_THEME_RATE_OK"
  elif [ "$pct" -gt 50 ]; then
    color="$_THEME_RATE_WARN"
  else
    color="$_THEME_RATE_CRIT"
  fi

  printf '%b%s%d%%%b' "$color" "$prefix" "$pct" "$_CLR_RESET"
}
