#!/usr/bin/env bash
# help.sh — comprehensive help output (human + Claude-readable)

cc_show_help() {
  cat <<'HELPTEXT'
claude-statusline — Configurable statusline for Claude Code

USAGE
  bash statusline.sh [OPTIONS]
  Reads JSON from stdin (provided by Claude Code).

  In ~/.claude/settings.json:
  {
    "statusLine": {
      "type": "command",
      "command": "bash /path/to/statusline.sh --segments directory,context_bar,model,cost --theme default"
    }
  }

OPTIONS
  --segments LIST       Comma-separated segment names, in display order
                        Default: directory,context_bar
  --theme NAME          Color theme: default, minimal, neon, monochrome
                        Default: default
  --bar-width N         Bar width in characters (context_bar + rate bar)
                        Default: 20
  --bar-style STYLE     Bar characters: block, shade, dot, ascii
                        Default: block
  --separator STR       String between segments
                        Default: " | "
  --rate-style STYLE    Rate limits display: compact, dot, full
                        Default: compact
  --icons STYLE         Icon set: nerd, unicode, none (or custom from icons/)
                        Default: nerd
  --no-icons            Alias for --icons none
  --no-color            Disable all ANSI (forces monochrome theme)
  --config PATH         Config file path
                        Default: ~/.config/claude-statusline/config
  --help                Show this help

CONFIG FILE
  Path: ~/.config/claude-statusline/config
  Format (one KEY=VALUE per line):
    SEGMENTS=directory,context_bar,model
    THEME=default
    BAR_WIDTH=20
    BAR_STYLE=block
    SEPARATOR= |
    RATE_STYLE=compact
    ICONS=nerd

  Priority: CLI flags > config file > built-in defaults

SEGMENTS
  directory       Project directory (last 2 path components)
                  Example:  Tapelet/src
  context_bar     Context window usage bar with gradient colors
                  Example: ■■■■■■■■■■■■□□□□□□□□□□□□□□□□□□ 42%
  context_pct     Context window percentage (number only)
                  Example: 42%
  model           Model display name
                  Example:  Opus
  cost            Session cost in USD
                  Example:  $1.23
  rate_limits     API rate limit usage (see --rate-style)
                  Example: 5h:23% · 7d:41%
  vim_mode        Vim mode indicator
                  Example: NORMAL
  worktree        Git worktree name
                  Example:  feature-xyz
  session_time    Session duration
                  Example:  12m 34s
  lines_changed   Lines added/removed
                  Example: +156 -23

  All segments use only JSON stdin data. No shell commands or filesystem access.

THEMES
  default         Green→yellow→red gradient (recommended)
  minimal         Dim/subtle colors throughout
  neon            Bold vivid 256-color
  monochrome      No ANSI codes, ASCII-only

BAR STYLES (--bar-style)
  block           ■■■■■■□□□□□□  (default)
  shade           ████████░░░░
  dot             ●●●●●●○○○○○○
  ascii           ######------

RATE LIMIT STYLES (--rate-style)
  compact         5h:23% · 7d:41%                        (default)
  dot             ● (colored by worst pace)
  full            5h ■■■■■■□□ 77% ⟳2h · 7d ■■■■□□□□ 59% ⟳4d

  Colors are pace-based: projected usage at end of window.
  Green <70%, yellow 70-90%, red >90% projected.

EXAMPLES
  Minimal:
    bash statusline.sh --segments directory,context_bar

  Full monitoring:
    bash statusline.sh --segments directory,context_bar,model,cost,rate_limits --rate-style dot

  Developer:
    bash statusline.sh --segments directory,context_bar,model,lines_changed,session_time

  No icons (no Nerd Font):
    bash statusline.sh --segments directory,context_bar,model --no-icons

  Plain text:
    bash statusline.sh --no-icons --no-color

JSON INPUT
  Reads Claude Code statusline JSON from stdin. Key fields:
    .workspace.current_dir          Current directory
    .workspace.git_worktree         Git worktree name
    .model.display_name             Model name
    .context_window.current_usage   Token counts (input, cache_creation, cache_read)
    .context_window.context_window_size  Window size (200000 or 1000000)
    .cost.total_cost_usd            Session cost
    .cost.total_duration_ms         Session duration
    .cost.total_lines_added         Lines added
    .cost.total_lines_removed       Lines removed
    .rate_limits.five_hour          5-hour rate limit (used_percentage, resets_at)
    .rate_limits.seven_day          7-day rate limit (used_percentage, resets_at)
    .vim.mode                       Vim mode (NORMAL/INSERT)
HELPTEXT
}
