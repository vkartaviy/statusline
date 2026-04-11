#!/usr/bin/env bash
# config.sh — defaults, config file loading, CLI flag parsing

cc_load_config() {
  # ── Built-in defaults ──
  _CFG_SEGMENTS="directory,context_bar"
  _CFG_THEME="default"
  _CFG_BAR_WIDTH=30
  _CFG_BAR_STYLE="block"
  _CFG_SEPARATOR=" | "
  _CFG_RATE_STYLE="compact"
  _CFG_ICONS=1
  _CFG_NO_COLOR=0
  _CFG_CONFIG="${HOME}/.config/claude-statusline/config"
  _CFG_SHOW_HELP=0

  # ── Source config file (if exists) ──
  # Parse CLI first pass: find --config flag
  local i
  for ((i=1; i<=$#; i++)); do
    local arg="${!i}"
    if [ "$arg" = "--config" ]; then
      local next=$((i+1))
      _CFG_CONFIG="${!next}"
    fi
  done

  if [ -f "$_CFG_CONFIG" ]; then
    local line key val
    while IFS= read -r line || [ -n "$line" ]; do
      # Skip comments and empty lines
      case "$line" in
        '#'*|'') continue ;;
      esac
      key="${line%%=*}"
      val="${line#*=}"
      case "$key" in
        SEGMENTS)   _CFG_SEGMENTS="$val" ;;
        THEME)      _CFG_THEME="$val" ;;
        BAR_WIDTH)  _CFG_BAR_WIDTH="$val" ;;
        BAR_STYLE)  _CFG_BAR_STYLE="$val" ;;
        SEPARATOR)  _CFG_SEPARATOR="$val" ;;
        RATE_STYLE) _CFG_RATE_STYLE="$val" ;;
        ICONS)      _CFG_ICONS="$val" ;;
      esac
    done < "$_CFG_CONFIG"
  fi

  # ── Parse CLI flags (highest priority) ──
  while [ $# -gt 0 ]; do
    case "$1" in
      --segments)   _CFG_SEGMENTS="$2"; shift 2 ;;
      --theme)      _CFG_THEME="$2"; shift 2 ;;
      --bar-width)  _CFG_BAR_WIDTH="$2"; shift 2 ;;
      --bar-style)  _CFG_BAR_STYLE="$2"; shift 2 ;;
      --separator)  _CFG_SEPARATOR="$2"; shift 2 ;;
      --rate-style) _CFG_RATE_STYLE="$2"; shift 2 ;;
      --no-icons)   _CFG_ICONS=0; shift ;;
      --no-color)   _CFG_NO_COLOR=1; shift ;;
      --config)     shift 2 ;;  # already handled
      --help)       _CFG_SHOW_HELP=1; shift ;;
      *)            shift ;;
    esac
  done

  # ── Resolve bar characters from style ──
  case "$_CFG_BAR_STYLE" in
    block) _CFG_BAR_FILLED="■"; _CFG_BAR_EMPTY="□" ;;
    shade) _CFG_BAR_FILLED="█"; _CFG_BAR_EMPTY="░" ;;
    dot)   _CFG_BAR_FILLED="●"; _CFG_BAR_EMPTY="○" ;;
    ascii) _CFG_BAR_FILLED="#"; _CFG_BAR_EMPTY="-" ;;
    *)     _CFG_BAR_FILLED="■"; _CFG_BAR_EMPTY="□" ;;
  esac

  # ── No-color forces monochrome theme ──
  if [ "$_CFG_NO_COLOR" -eq 1 ]; then
    _CFG_THEME="monochrome"
  fi
}
