#!/usr/bin/env bash
# preview.sh — visual preview of all themes, segments, bar styles, rate styles

set -f
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. "${_SCRIPT_DIR}/lib/colors.sh"
. "${_SCRIPT_DIR}/lib/config.sh"
. "${_SCRIPT_DIR}/lib/parse.sh"
. "${_SCRIPT_DIR}/lib/render.sh"

# Parse flags for preview-specific options
_PREVIEW_THEME=""
_PREVIEW_SEGMENTS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --theme)    _PREVIEW_THEME="$2"; shift 2 ;;
    --segments) _PREVIEW_SEGMENTS="$2"; shift 2 ;;
    *)          shift ;;
  esac
done

# ── Mock JSON generator ──
# Args: ctx_size input_tokens rate_5h rate_7d reset_5h_offset reset_7d_offset project_dir current_dir cache_read cache_create session_id
_mock_json() {
  local ctx_size="${1:-200000}"
  local input_tokens="${2:-65000}"
  local rate_5h="${3:-23}"
  local rate_7d="${4:-41}"
  local reset_5h_offset="${5:-8040}"
  local reset_7d_offset="${6:-345600}"
  local project_dir="${7:-/Users/vk/Dev/statusline}"
  local current_dir="${8:-$project_dir/segments}"
  local cache_read="${9:-50000}"
  local cache_create="${10:-10000}"
  local session_id="${11:-preview}"
  local now=$(date +%s)
  local reset_5h=$((now + reset_5h_offset))
  local reset_7d=$((now + reset_7d_offset))

  printf '{"session_id":"%s","model":{"display_name":"Opus 4.6"},"workspace":{"project_dir":"%s","current_dir":"%s","git_worktree":"feature-xyz"},"context_window":{"current_usage":{"input_tokens":%d,"cache_creation_input_tokens":%d,"cache_read_input_tokens":%d},"context_window_size":%d},"cost":{"total_cost_usd":13.50,"total_duration_ms":754000,"total_lines_added":156,"total_lines_removed":23},"rate_limits":{"five_hour":{"used_percentage":%s,"resets_at":%d},"seven_day":{"used_percentage":%s,"resets_at":%d}},"vim":{"mode":"NORMAL"}}' \
    "$session_id" "$project_dir" "$current_dir" "$input_tokens" "$cache_create" "$cache_read" "$ctx_size" "$rate_5h" "$reset_5h" "$rate_7d" "$reset_7d"
}

_header() {
  printf '\n\033[1m━━━ %s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n' "$1"
}

_run() {
  local json="$1"; shift
  printf '%s' "$json" | bash "${_SCRIPT_DIR}/statusline.sh" "$@"
}

# ── Preview ──

if [ -n "$_PREVIEW_THEME" ]; then
  _header "Theme: $_PREVIEW_THEME"
  segs="${_PREVIEW_SEGMENTS:-project,directory,context_bar,cost,rate_limits}"
  _run "$(_mock_json)" --segments "$segs" --theme "$_PREVIEW_THEME" --rate-style full
  exit 0
fi

segs="${_PREVIEW_SEGMENTS:-project,directory,worktree,context_bar,cost}"

# Themes
_header "Themes"
for theme in default minimal neon monochrome; do
  printf '  %-13s' "$theme:"
  _run "$(_mock_json)" --segments "$segs" --theme "$theme"
done

# Icon Sets
_header "Icon Sets"
for icons in nerd unicode none; do
  printf '  %-13s' "$icons:"
  _run "$(_mock_json)" --segments project,directory,cost,worktree,session_time --theme neon --icons "$icons"
done

# Context Window sizes
_header "Context Window"
printf '  %-13s' "200K @32%:"
_run "$(_mock_json 200000 50000)" --segments context_bar
printf '  %-13s' "200K @85%:"
_run "$(_mock_json 200000 155000)" --segments context_bar
printf '  %-13s' " 1M  @8%:"
_run "$(_mock_json 1000000 65000)" --segments context_bar
printf '  %-13s' " 1M  @65%:"
_run "$(_mock_json 1000000 635000)" --segments context_bar

# Bar Styles
_header "Bar Styles"
for style in block shade dot ascii; do
  printf '  %-13s' "$style:"
  _run "$(_mock_json)" --segments context_bar --bar-style "$style"
done

# Directory Collapse (smart)
_header "Directory Collapse"
printf '  %-20s' "In root:"
_run "$(_mock_json 200000 65000 23 41 8040 345600 /Users/vk/Dev/statusline /Users/vk/Dev/statusline)" --segments project,directory --theme neon
printf '  %-20s' "Short path:"
_run "$(_mock_json 200000 65000 23 41 8040 345600 /Users/vk/Dev/myapp /Users/vk/Dev/myapp/src)" --segments project,directory --theme neon
printf '  %-20s' "3 levels (fits):"
_run "$(_mock_json 200000 65000 23 41 8040 345600 /Users/vk/Dev/myapp /Users/vk/Dev/myapp/apps/web/src)" --segments project,directory --theme neon
printf '  %-20s' "Long (collapsed):"
_run "$(_mock_json 200000 65000 23 41 8040 345600 /Users/vk/Dev/myapp /Users/vk/Dev/myapp/packages/authentication/src/middleware)" --segments project,directory --theme neon

# Rate Limit Styles
_header "Rate Limit Styles"
for style in compact dot full; do
  printf '  %-13s' "$style:"
  _run "$(_mock_json)" --segments rate_limits --rate-style "$style"
done

# Pace visualization (full rate style, 3-zone bar)
# 5h window = 18000s. Pace = used% × 5h / elapsed. Requires elapsed > 20% and used > 20%.
_header "Pace (full rate style — 3-zone bar: ■ safe, ▪ at-risk, □ used)"
# Low: 30% used, 3h elapsed (60%) → pace = 30*5/3 = 50% → green
printf '  %-20s' "Low pace (safe):"
_run "$(_mock_json 200000 65000 30 25 7200 518400)" --segments rate_limits --rate-style full
# Moderate: 30% used, 2h elapsed (40%) → pace = 30*5/2 = 75% → yellow
printf '  %-20s' "Moderate pace:"
_run "$(_mock_json 200000 65000 30 20 10800 518400)" --segments rate_limits --rate-style full
# High: 55% used, 2h elapsed (40%) → pace = 55*5/2 = 137% → clamped to 100 → red
printf '  %-20s' "High pace (danger):"
_run "$(_mock_json 200000 65000 55 15 10800 561600)" --segments rate_limits --rate-style full

# Cache Health (4 stages — healthy / mid / poor / miss)
_header "Cache Health"
_cache_demo() {
  local label="$1" sid="$2" read="$3" create="$4"
  local state_file="${TMPDIR:-/tmp}/claude-statusline/${sid}.cache"
  rm -f "$state_file" 2>/dev/null
  local json
  json=$(_mock_json 200000 65000 23 41 8040 345600 \
    /Users/vk/Dev/statusline /Users/vk/Dev/statusline/segments \
    "$read" "$create" "$sid")
  printf '  %-22s' "$label"
  # Run 3 times: healthy paths show on first call, "miss" only on third
  _run "$json" --segments cache_health > /dev/null
  _run "$json" --segments cache_health > /dev/null
  _run "$json" --segments cache_health
}
_cache_demo "Healthy (90% hit):" health-90   90000 10000
_cache_demo "Mid (60% hit):"     health-60   60000 40000
_cache_demo "Poor (30% hit):"    health-30   30000 70000
_cache_demo "Miss (thrashing):"  health-miss     0 50000

# All Segments (with project added)
_header "All Segments"
for seg in project directory context_bar context_pct model cost rate_limits cache_health vim_mode worktree session_time lines_changed; do
  printf '  %-16s' "$seg:"
  _run "$(_mock_json)" --segments "$seg"
done

# Example Configs
_header "Example Configs"
printf '  %-13s' "Minimal:"
echo "statusline.sh --segments project,context_bar"
printf '  %-13s' "Full:"
echo "statusline.sh --segments project,directory,context_bar,cost,rate_limits --theme neon --icons nerd --rate-style full"
printf '  %-13s' "Developer:"
echo "statusline.sh --segments project,directory,context_bar,lines_changed,session_time"
printf '  %-13s' "Plain:"
echo "statusline.sh --icons none --no-color"

echo ""
