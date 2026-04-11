#!/usr/bin/env bash
# parse.sh — single-jq JSON parser → $_CC_* variables

cc_parse_input() {
  _CC_RAW=$(cat)

  # Empty or whitespace-only input — nothing to parse
  case "$_CC_RAW" in
    ''|*[!\ ]*) ;;
    *) return 1 ;;
  esac
  [ -z "$_CC_RAW" ] && return 1

  # Use Unit Separator (\x1f) as delimiter — tab is "IFS whitespace"
  # and bash collapses consecutive tabs, dropping empty fields.
  # Note: bash 3.2 also has a bug where \x01 (SOH) doesn't work as IFS.
  local _US
  _US=$(printf '\037')

  local parsed
  parsed=$(printf '%s' "$_CC_RAW" | jq -r '[
    .workspace.current_dir // "",
    .workspace.git_worktree // "",
    .model.display_name // "",
    (.context_window.current_usage.input_tokens // 0),
    (.context_window.current_usage.cache_creation_input_tokens // 0),
    (.context_window.current_usage.cache_read_input_tokens // 0),
    (.context_window.context_window_size // 0),
    ((.cost.total_cost_usd // 0) * 100 | round / 100),
    (.cost.total_duration_ms // 0),
    (.cost.total_lines_added // 0),
    (.cost.total_lines_removed // 0),
    (.rate_limits.five_hour.used_percentage // -1),
    (.rate_limits.five_hour.resets_at // -1),
    (.rate_limits.seven_day.used_percentage // -1),
    (.rate_limits.seven_day.resets_at // -1),
    .vim.mode // ""
  ] | map(tostring) | join("\u001f")' 2>/dev/null) || return 1

  IFS="$_US" read -r \
    _CC_CWD _CC_WORKTREE _CC_MODEL \
    _CC_INPUT_TOKENS _CC_CACHE_CREATE _CC_CACHE_READ \
    _CC_CTX_SIZE _CC_COST _CC_DURATION_MS \
    _CC_LINES_ADDED _CC_LINES_REMOVED \
    _CC_RATE_5H _CC_RATE_5H_RESET _CC_RATE_7D _CC_RATE_7D_RESET \
    _CC_VIM_MODE \
    <<< "$parsed"
}
