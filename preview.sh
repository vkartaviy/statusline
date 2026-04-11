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
_mock_json() {
  local ctx_size="${1:-200000}"
  local input_tokens="${2:-65000}"
  local rate_5h="${3:-23}"
  local rate_7d="${4:-41}"
  local reset_5h_offset="${5:-8040}"    # seconds until reset (default ~2h14m)
  local reset_7d_offset="${6:-345600}"  # default ~4d
  local now=$(date +%s)
  local reset_5h=$((now + reset_5h_offset))
  local reset_7d=$((now + reset_7d_offset))

  printf '{"model":{"display_name":"Opus"},"workspace":{"current_dir":"/Users/vk/Dev/Tapelet/src","git_worktree":"feature-xyz"},"context_window":{"current_usage":{"input_tokens":%d,"cache_creation_input_tokens":10000,"cache_read_input_tokens":5000},"context_window_size":%d},"cost":{"total_cost_usd":1.23,"total_duration_ms":754000,"total_lines_added":156,"total_lines_removed":23},"rate_limits":{"five_hour":{"used_percentage":%s,"resets_at":%d},"seven_day":{"used_percentage":%s,"resets_at":%d}},"vim":{"mode":"NORMAL"}}' \
    "$input_tokens" "$ctx_size" "$rate_5h" "$reset_5h" "$rate_7d" "$reset_7d"
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
  # Single theme preview
  _header "Theme: $_PREVIEW_THEME"
  local segs="${_PREVIEW_SEGMENTS:-directory,context_bar,model,cost,rate_limits,vim_mode,worktree,session_time,lines_changed}"
  _run "$(_mock_json)" --segments "$segs" --theme "$_PREVIEW_THEME"
  exit 0
fi

segs="${_PREVIEW_SEGMENTS:-directory,context_bar,model,cost}"

# Themes
_header "Themes"
for theme in default minimal neon monochrome; do
  printf '  %-13s' "$theme:"
  _run "$(_mock_json)" --segments "$segs" --theme "$theme"
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

# Rate Limit Styles
_header "Rate Limit Styles"
for style in compact dot full; do
  printf '  %-13s' "$style:"
  _run "$(_mock_json)" --segments rate_limits --rate-style "$style"
done

# Pace visualization (full rate style)
_header "Pace (full rate style)"
printf '  %-20s' "Low pace (safe):"
# 23% used, 2h left of 5h → pace ~38%
_run "$(_mock_json 200000 65000 23 41 7200 345600)" --segments rate_limits --rate-style full
printf '  %-20s' "Moderate pace:"
# 40% used, 2.5h left of 5h → pace ~80%
_run "$(_mock_json 200000 65000 40 30 9000 518400)" --segments rate_limits --rate-style full
printf '  %-20s' "High pace (danger):"
# 50% used, 4h left of 5h → pace 250%
_run "$(_mock_json 200000 65000 50 10 14400 561600)" --segments rate_limits --rate-style full

# All Segments
_header "All Segments"
for seg in directory context_bar context_pct model cost rate_limits vim_mode worktree session_time lines_changed; do
  printf '  %-16s' "$seg:"
  _run "$(_mock_json)" --segments "$seg"
done

# Example Configs
_header "Example Configs"
printf '  %-13s' "Minimal:"
echo "statusline.sh --segments directory,context_bar"
printf '  %-13s' "Full:"
echo "statusline.sh --segments directory,context_bar,model,cost,rate_limits --rate-style dot"
printf '  %-13s' "Developer:"
echo "statusline.sh --segments directory,context_bar,model,lines_changed,session_time"

echo ""
