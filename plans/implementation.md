# Implementation Plan: claude-statusline

## Context

Configurable statusline for Claude Code. Single bash script + sourced modules. Published as a standalone GitHub project.

**Data source:** Only JSON from Claude Code stdin — no shell commands, no filesystem access.
**Performance target:** <20ms (one `jq` call, rest is bash arithmetic).
**Compatibility:** macOS bash 3.2+ (no associative arrays, no `mapfile`, no `${var,,}`).
**Dependencies:** `jq` + coreutils only.

---

## Project Structure

```
statusline/
├── statusline.sh                # Main entry point
├── lib/
│   ├── colors.sh                # ANSI codes, $_CLR_* constants
│   ├── config.sh                # Defaults, config file loading, CLI parsing
│   ├── help.sh                  # --help output (human + Claude-readable)
│   ├── parse.sh                 # Single-jq JSON parser → $_CC_* variables
│   └── render.sh                # Segment pipeline: source → call → join
├── segments/
│   ├── directory.sh             #  project/src
│   ├── context_bar.sh           # ■■■■■□□□□□ 42%
│   ├── context_pct.sh           # 42% (number only)
│   ├── model.sh                 #  Opus
│   ├── cost.sh                  #  $1.23
│   ├── rate_limits.sh           # 5h:23% · 7d:41% (4 sub-styles)
│   ├── vim_mode.sh              # NORMAL / INSERT
│   ├── worktree.sh              #  feature-xyz
│   ├── session_time.sh          #  12m 34s
│   └── lines_changed.sh        # +156 -23
├── themes/
│   ├── default.sh               # Green→yellow→red gradient
│   ├── minimal.sh               # Dim/subtle
│   ├── neon.sh                  # Bold vivid 256-color
│   └── monochrome.sh            # No ANSI, ASCII-only
├── preview.sh                   # Visual preview with mock JSON
├── install.sh                   # Git clone → symlink + config
├── examples/
│   └── settings.json            # Example Claude Code settings
├── LICENSE                      # MIT
└── README.md
```

---

## CLI Options

| Flag | Default | Description |
|------|---------|-------------|
| `--segments LIST` | `directory,context_bar` | Comma-separated segment names, in display order |
| `--theme NAME` | `default` | Color theme: `default`, `minimal`, `neon`, `monochrome` |
| `--bar-width N` | `30` | Bar width in chars (applies to context_bar + rate bar) |
| `--bar-style STYLE` | `block` | Bar characters: `block`, `shade`, `dot`, `ascii` |
| `--separator STR` | ` \| ` | String between segments |
| `--rate-style STYLE` | `compact` | Rate limits display: `compact`, `bar`, `dot`, `full` |
| `--no-icons` | off (icons on) | Disable Nerd Font glyphs |
| `--no-color` | off | Disable all ANSI (forces monochrome theme) |
| `--config PATH` | `~/.config/claude-statusline/config` | Path to config file |
| `--help` | — | Comprehensive help (human + Claude-readable) |

**Config hierarchy:** CLI flags > config file > built-in defaults.

**Config file format** (`~/.config/claude-statusline/config`):
```
SEGMENTS=directory,context_bar,model
THEME=default
BAR_WIDTH=30
BAR_STYLE=block
SEPARATOR= | 
RATE_STYLE=compact
ICONS=1
```

**Usage in `~/.claude/settings.json`:**
```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/Development/Tools/statusline/statusline.sh --segments directory,context_bar,model,cost --theme default"
  }
}
```

---

## Key Architecture Details

### Single-jq parse (`lib/parse.sh`)

One `jq` call extracts ALL fields into tab-separated values. Every segment reads `$_CC_*` shell vars — zero additional I/O.

```bash
cc_parse_input() {
  _CC_RAW=$(cat)
  local parsed
  parsed=$(echo "$_CC_RAW" | jq -r '[
    .workspace.current_dir // "",
    .workspace.git_worktree // "",
    .model.display_name // "",
    (.context_window.current_usage.input_tokens // 0),
    (.context_window.current_usage.cache_creation_input_tokens // 0),
    (.context_window.current_usage.cache_read_input_tokens // 0),
    (.context_window.context_window_size // 200000),
    (.cost.total_cost_usd // 0),
    (.cost.total_duration_ms // 0),
    (.cost.total_lines_added // 0),
    (.cost.total_lines_removed // 0),
    (.rate_limits.five_hour.used_percentage // -1),
    (.rate_limits.five_hour.resets_at // -1),
    (.rate_limits.seven_day.used_percentage // -1),
    (.rate_limits.seven_day.resets_at // -1),
    .vim.mode // ""
  ] | @tsv')

  IFS=$'\t' read -r \
    _CC_CWD _CC_WORKTREE _CC_MODEL \
    _CC_INPUT_TOKENS _CC_CACHE_CREATE _CC_CACHE_READ \
    _CC_CTX_SIZE _CC_COST _CC_DURATION_MS \
    _CC_LINES_ADDED _CC_LINES_REMOVED \
    _CC_RATE_5H _CC_RATE_5H_RESET _CC_RATE_7D _CC_RATE_7D_RESET \
    _CC_VIM_MODE \
    <<< "$parsed"
}
```

### Segment interface

Each file defines one function `segment_<name>`. Reads `$_CC_*` + `$_THEME_*` globals. Prints to stdout. Returns 1 if data missing (segment hidden).

```bash
# Example: segments/model.sh
segment_model() {
  [ -z "$_CC_MODEL" ] && return 1
  local icon=""
  [ "$_CFG_ICONS" -eq 1 ] && icon=" "
  printf '%b%s%s%b' "$_THEME_MODEL" "$icon" "$_CC_MODEL" "$_CLR_RESET"
}
```

### Theme system

Each theme sets `_THEME_*` variables. Segments reference these — never hardcode colors.

```bash
# themes/default.sh — green→yellow→red gradient (ported from current statusline)
_THEME_BAR_LOW="\033[2;32m"      # dim green  (0-50%)
_THEME_BAR_MED="\033[2;33m"      # dim yellow (50-70%)
_THEME_BAR_HIGH="\033[2;31m"     # dim red    (70-80%)
_THEME_BAR_CRIT="\033[0;31m"     # bright red (80-100%)
_THEME_BAR_EMPTY="\033[2;37m"    # dim white
_THEME_DIR="\033[0;37m"
_THEME_MODEL="\033[0;36m"        # cyan
_THEME_COST="\033[0;33m"         # yellow
_THEME_RATE_OK="\033[0;32m"      # green
_THEME_RATE_WARN="\033[0;31m"    # red
_THEME_VIM_N="\033[0;32m"        # green (NORMAL)
_THEME_VIM_I="\033[0;34m"        # blue (INSERT)
_THEME_WORKTREE="\033[0;35m"     # magenta
_THEME_LINES_ADD="\033[0;32m"    # green
_THEME_LINES_DEL="\033[0;31m"    # red
_THEME_TIME="\033[2;37m"         # dim white
_THEME_SEP="\033[2;37m"          # dim white
_THEME_LABEL="\033[2;37m"        # dim white
```

### Render pipeline (`lib/render.sh`)

1. Split `$_CFG_SEGMENTS` by comma
2. For each segment name, source `segments/<name>.sh` if file exists
3. Call `segment_<name>`, capture output
4. Collect non-empty outputs into array
5. Join with themed separator, print with newline

### Bar styles (`--bar-style`)

Applies globally to context_bar and rate_limits bar.

| Style | Filled | Empty | Example |
|-------|--------|-------|---------|
| `block` | `■` | `□` | `■■■■■■□□□□□□` |
| `shade` | `█` | `░` | `██████░░░░░░` |
| `dot` | `●` | `○` | `●●●●●●○○○○○○` |
| `ascii` | `#` | `-` | `######------` |

Set via `_CFG_BAR_FILLED` and `_CFG_BAR_EMPTY` in config.sh based on `--bar-style`.

### Rate limits styles (`--rate-style`)

| Style | Output | Description |
|-------|--------|-------------|
| `compact` | `5h:23% · 7d:41%` | Default, concise |
| `bar` | `5h ■■□□□□□□ 7d ■■■□□□□□` | Same gradient as context_bar, 8-char width |
| `dot` | `●` (colored) | Single dot: green <50%, yellow 50-80%, red >80% (worst of both) |
| `full` | `5h:23% ⟳2h14m · 7d:41% ⟳4d` | Percentage + countdown to reset |

Color thresholds: green <50%, yellow 50-80%, red >80%.
Countdown: `resets_at` (Unix epoch) minus `$(date +%s)`, formatted as `Xh Ym` or `Xd`.

---

## Segments Reference

| Segment | JSON source | Output example | Nerd Font icon |
|---------|-------------|---------------|----------------|
| `directory` | `.workspace.current_dir` | ` Tapelet/src` |  |
| `context_bar` | `.context_window.current_usage.*` | `■■■■■□□□□□ 42%` | — |
| `context_pct` | same as above | `42%` | — |
| `model` | `.model.display_name` | ` Opus` |  |
| `cost` | `.cost.total_cost_usd` | ` $1.23` |  |
| `rate_limits` | `.rate_limits.*` | varies by `--rate-style` | — |
| `vim_mode` | `.vim.mode` | `NORMAL` | — |
| `worktree` | `.workspace.git_worktree` | ` feat-xyz` |  |
| `session_time` | `.cost.total_duration_ms` | ` 12m 34s` |  |
| `lines_changed` | `.cost.total_lines_*` | `+156 -23` | — |

All segments use **only JSON stdin data**. No shell commands, no filesystem access.

Context bar handles both 200K and 1M windows automatically — `pct = tokens * 100 / context_window_size`.

---

## `--help` as Claude-readable Interface

The `--help` output is **self-sufficient documentation**. When Claude Code reads it (e.g. user says "set up my statusline"), Claude can parse and configure everything without external docs.

Sections:
1. Usage line — exact command format for `settings.json`
2. All flags — with defaults and valid values
3. Segment catalog — name, description, output example, JSON source
4. Theme catalog — name, description
5. Bar style catalog — name, characters, example
6. Rate style catalog — name, output example
7. Example configurations — ready-to-copy `settings.json` snippets
8. JSON input schema summary — what fields the script reads

---

## Preview Script (`preview.sh`)

Visual preview — shows all themes, segments, bar styles, rate styles, context window sizes side by side. Uses built-in mock JSON, no stdin needed.

```
━━━ Themes ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
default:     Tapelet/src │ ■■■■■■■■■■■■□□□□□□□□□□□□□□□□□□ 42% │  Opus │  $1.23
minimal:     Tapelet/src · ·····○○○○○○○○○○○○○○○○○○○○○○○○○ 42% · Opus · $1.23
neon:        Tapelet/src │ ████████████░░░░░░░░░░░░░░░░░░ 42% │  Opus │  $1.23
monochrome:  Tapelet/src | ############------------------ 42% | Opus | $1.23

━━━ Context Window ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
200K @42%:  ■■■■■■■■■■■■□□□□□□□□□□□□□□□□□□ 42%
200K @85%:  ■■■■■■■■■■■■■■■■■■■■■■■■■□□□□□ 85%
 1M  @8%:   ■■□□□□□□□□□□□□□□□□□□□□□□□□□□□□ 8%
 1M  @65%:  ■■■■■■■■■■■■■■■■■■■□□□□□□□□□□□ 65%

━━━ Bar Styles ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
block:   ■■■■■■■■■■■■□□□□□□□□□□□□□□□□□□ 42%
shade:   ████████████░░░░░░░░░░░░░░░░░░ 42%
dot:     ●●●●●●●●●●●●○○○○○○○○○○○○○○○○○○ 42%
ascii:   ############------------------ 42%

━━━ Rate Limit Styles ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
compact:  5h:23% · 7d:41%
bar:      5h ■■□□□□□□ 7d ■■■□□□□□
dot:      ●
full:     5h:23% ⟳2h14m · 7d:41% ⟳4d

━━━ All Segments ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
directory:      Tapelet/src
context_bar:    ■■■■■■■■■■■■□□□□□□□□□□□□□□□□□□ 42%
context_pct:    42%
model:           Opus
cost:            $1.23
rate_limits:    5h:23% · 7d:41%
vim_mode:       NORMAL
worktree:        feature-xyz
session_time:    12m 34s
lines_changed:  +156 -23

━━━ Example Configs ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Minimal:   statusline.sh --segments directory,context_bar
Full:      statusline.sh --segments directory,context_bar,model,cost,rate_limits --rate-style dot
Developer: statusline.sh --segments directory,context_bar,model,lines_changed,session_time
```

Flags:
- `./preview.sh` — show everything
- `./preview.sh --theme neon` — preview one theme with all segments
- `./preview.sh --segments directory,context_bar,model` — preview specific combo

Implementation: sources the same `lib/` and `segments/` as the main script. Generates mock JSON, loops through scenarios.

---

## Implementation Steps (Progress Tracker)

### Phase 1: Core Library
- [x] **1.1** `lib/colors.sh` — `_CLR_RESET` constant, no-color support
- [x] **1.2** `lib/config.sh` — `cc_load_config()`: set defaults, source config file, parse CLI flags (`--segments`, `--theme`, `--bar-width`, `--bar-style`, `--separator`, `--rate-style`, `--no-icons`, `--no-color`, `--config`, `--help`)
- [x] **1.3** `lib/parse.sh` — `cc_parse_input()`: single `jq` call, `IFS=$'\t' read` into `$_CC_*` vars
- [x] **1.4** `lib/render.sh` — `cc_render()`: iterate segments, source files, call functions, join with separator
- [x] **1.5** `lib/help.sh` — `cc_show_help()`: structured help output with all catalogs and examples

### Phase 2: Themes
- [x] **2.1** `themes/default.sh` — green→yellow→red gradient (port from current `~/.claude/statusline.sh`)
- [x] **2.2** `themes/monochrome.sh` — all `_THEME_*` empty, no ANSI
- [x] **2.3** `themes/minimal.sh` — dim colors throughout
- [x] **2.4** `themes/neon.sh` — bold vivid 256-color

### Phase 3: Core Segments
- [x] **3.1** `segments/directory.sh` — `segment_directory()`: last two path components from `$_CC_CWD`, icon ``
- [x] **3.2** `segments/context_bar.sh` — `segment_context_bar()`: gradient bar with `$_CFG_BAR_WIDTH`, `$_CFG_BAR_FILLED`/`$_CFG_BAR_EMPTY`, color thresholds from theme. Port logic from current statusline
- [x] **3.3** `segments/context_pct.sh` — `segment_context_pct()`: just the percentage number
- [x] **3.4** `segments/model.sh` — `segment_model()`: model display name, icon ``

### Phase 4: Main Entry Point + Test
- [x] **4.1** `statusline.sh` — wire `lib/` + `themes/` + `segments/`, handle `--help` early exit
- [x] **4.2** Test with mock JSON (200K context, all fields populated)
- [x] **4.3** Test with empty JSON `{}` — no errors, no output
- [x] **4.4** Test with 1M context window
- [x] **4.5** Performance test: `time echo '...' | bash statusline.sh` — target <20ms

### Phase 5: Remaining Segments
- [x] **5.1** `segments/cost.sh` — `segment_cost()`: format as `$X.XX`, icon ``
- [x] **5.2** `segments/rate_limits.sh` — `segment_rate_limits()`: 4 sub-styles (compact, bar, dot, full), countdown calculation for `full`
- [x] **5.3** `segments/vim_mode.sh` — `segment_vim_mode()`: colored by mode (NORMAL=green, INSERT=blue)
- [x] **5.4** `segments/worktree.sh` — `segment_worktree()`: worktree name, icon ``
- [x] **5.5** `segments/session_time.sh` — `segment_session_time()`: ms→`Xm Ys` format, icon ``
- [x] **5.6** `segments/lines_changed.sh` — `segment_lines_changed()`: `+N -M` colored green/red

### Phase 6: Preview + Install
- [x] **6.1** `preview.sh` — visual preview: themes, context sizes, bar styles, rate styles, all segments, example configs
- [x] **6.2** `install.sh` — symlink to `~/.local/bin/`, copy default config to `~/.config/claude-statusline/`
- [x] **6.3** `examples/settings.json` — ready-to-copy Claude Code settings for common setups

### Phase 7: Documentation + Ship
- [x] **7.1** `README.md` — overview, install, usage, segments, themes, bar styles, rate styles, examples, screenshots
- [x] **7.2** `LICENSE` — MIT
- [x] **7.3** `git init` + initial commit
- [ ] **7.4** Plug into Claude Code settings and verify live rendering
- [x] **7.5** Final performance verification

---

## Verification Checklist

```bash
# Basic functionality
echo '{"model":{"display_name":"Opus"},"workspace":{"current_dir":"/Users/vk/Dev/Tapelet"},"context_window":{"current_usage":{"input_tokens":50000,"cache_creation_input_tokens":10000,"cache_read_input_tokens":5000},"context_window_size":200000},"cost":{"total_cost_usd":1.23,"total_duration_ms":300000,"total_lines_added":156,"total_lines_removed":23}}' \
  | bash statusline.sh --segments directory,context_bar,model,cost

# Each theme
... | bash statusline.sh --theme default
... | bash statusline.sh --theme minimal
... | bash statusline.sh --theme neon
... | bash statusline.sh --theme monochrome

# Bar styles
... | bash statusline.sh --bar-style block
... | bash statusline.sh --bar-style shade
... | bash statusline.sh --bar-style dot
... | bash statusline.sh --bar-style ascii

# Rate styles
... | bash statusline.sh --segments rate_limits --rate-style compact
... | bash statusline.sh --segments rate_limits --rate-style bar
... | bash statusline.sh --segments rate_limits --rate-style dot
... | bash statusline.sh --segments rate_limits --rate-style full

# Edge cases
echo '{}' | bash statusline.sh                           # empty JSON — no errors
... | bash statusline.sh --segments foo,directory         # invalid segment — skipped
... | bash statusline.sh --no-icons --no-color            # plain text mode

# 1M context
echo '{"context_window":{"current_usage":{"input_tokens":80000,"cache_creation_input_tokens":0,"cache_read_input_tokens":0},"context_window_size":1000000}}' \
  | bash statusline.sh --segments context_bar

# Performance
time echo '...' | bash statusline.sh                     # target <20ms

# Live test
# Update ~/.claude/settings.json → restart Claude Code → verify rendering
```

---

## Reference: Claude Code Statusline JSON Schema

```json
{
  "cwd": "/current/dir",
  "session_id": "abc123",
  "model": {
    "id": "claude-opus-4-6",
    "display_name": "Opus"
  },
  "workspace": {
    "current_dir": "/current/dir",
    "project_dir": "/project/dir",
    "git_worktree": "feature-xyz"
  },
  "context_window": {
    "context_window_size": 200000,
    "used_percentage": 42,
    "remaining_percentage": 58,
    "current_usage": {
      "input_tokens": 50000,
      "output_tokens": 1200,
      "cache_creation_input_tokens": 10000,
      "cache_read_input_tokens": 5000
    }
  },
  "cost": {
    "total_cost_usd": 1.23,
    "total_duration_ms": 300000,
    "total_lines_added": 156,
    "total_lines_removed": 23
  },
  "rate_limits": {
    "five_hour": {
      "used_percentage": 23.5,
      "resets_at": 1738425600
    },
    "seven_day": {
      "used_percentage": 41.2,
      "resets_at": 1738857600
    }
  },
  "vim": {
    "mode": "NORMAL"
  }
}
```

Fields that may be absent/null: `vim`, `rate_limits`, `workspace.git_worktree`, `context_window.current_usage` (null before first API call).
