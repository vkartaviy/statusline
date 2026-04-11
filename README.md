# claude-statusline

Configurable statusline for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Single bash script, modular segments, multiple themes.

```
 Tapelet/src | ■■■■■■■■■□□□□□□□□□□□□□□□□□□□□□ 32% |  Opus |  $1.23
```

## Features

- **10 segments** — directory, context bar, context %, model, cost, rate limits, vim mode, worktree, session time, lines changed
- **4 themes** — default (gradient), minimal, neon, monochrome
- **4 bar styles** — block `■□`, shade `█░`, dot `●○`, ascii `#-`
- **4 rate limit styles** — compact, bar, dot, full (with countdown)
- **Fast** — single `jq` call, rest is bash arithmetic (~25ms)
- **Compatible** — macOS bash 3.2+, no dependencies beyond `jq`

## Install

```bash
git clone https://github.com/user/claude-statusline.git
cd claude-statusline
bash install.sh
```

Or manually — add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash /path/to/statusline.sh --segments directory,context_bar,model,cost --theme default"
  }
}
```

## Usage

```
bash statusline.sh [OPTIONS]
```

| Option | Default | Description |
|--------|---------|-------------|
| `--segments LIST` | `directory,context_bar` | Comma-separated segment names |
| `--theme NAME` | `default` | Theme: `default`, `minimal`, `neon`, `monochrome` |
| `--bar-width N` | `30` | Bar width in characters |
| `--bar-style STYLE` | `block` | Bar style: `block`, `shade`, `dot`, `ascii` |
| `--separator STR` | ` \| ` | String between segments |
| `--rate-style STYLE` | `compact` | Rate display: `compact`, `bar`, `dot`, `full` |
| `--no-icons` | off | Disable Nerd Font glyphs |
| `--no-color` | off | Disable all ANSI codes |
| `--config PATH` | `~/.config/claude-statusline/config` | Config file path |
| `--help` | — | Show help |

Config hierarchy: CLI flags > config file > built-in defaults.

## Segments

| Segment | Output | Description |
|---------|--------|-------------|
| `directory` | ` Tapelet/src` | Last 2 path components |
| `context_bar` | `■■■■■□□□□□ 42%` | Context window usage bar |
| `context_pct` | `42%` | Context percentage only |
| `model` | ` Opus` | Model display name |
| `cost` | ` $1.23` | Session cost |
| `rate_limits` | `5h:23% · 7d:41%` | API rate limits |
| `vim_mode` | `NORMAL` | Vim mode indicator |
| `worktree` | ` feature-xyz` | Git worktree name |
| `session_time` | ` 12m 34s` | Session duration |
| `lines_changed` | `+156 -23` | Lines added/removed |

All segments read only JSON stdin from Claude Code — no shell commands, no filesystem access.

## Themes

| Theme | Description |
|-------|-------------|
| `default` | Green→yellow→red gradient |
| `minimal` | Dim/subtle colors |
| `neon` | Bold vivid 256-color |
| `monochrome` | No ANSI codes |

## Preview

```bash
bash preview.sh              # Show everything
bash preview.sh --theme neon  # Preview one theme
```

## Examples

**Minimal:**
```json
{ "statusLine": { "type": "command", "command": "bash statusline.sh --segments directory,context_bar" } }
```

**Full monitoring:**
```json
{ "statusLine": { "type": "command", "command": "bash statusline.sh --segments directory,context_bar,model,cost,rate_limits --rate-style dot" } }
```

**Developer:**
```json
{ "statusLine": { "type": "command", "command": "bash statusline.sh --segments directory,context_bar,model,lines_changed,session_time" } }
```

**Plain text (no Nerd Font):**
```json
{ "statusLine": { "type": "command", "command": "bash statusline.sh --segments directory,context_bar,model --no-icons --no-color" } }
```

## Config File

`~/.config/claude-statusline/config`:

```
SEGMENTS=directory,context_bar,model
THEME=default
BAR_WIDTH=30
BAR_STYLE=block
SEPARATOR= |
RATE_STYLE=compact
ICONS=1
```

## License

MIT
