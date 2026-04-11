# claude-statusline

Configurable statusline for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Single bash script, modular segments, multiple themes.

```
 Tapelet/src | ■■■■■■□□□□□□□□□□□□□□ 32% |  Opus | $1.23
```

## Features

- **10 segments** — directory, context bar, context %, model, cost, rate limits, vim mode, worktree, session time, lines changed
- **4 themes** — default (gradient), minimal, neon, monochrome
- **4 bar styles** — block `■□`, shade `█░`, dot `●○`, ascii `#-`
- **3 rate limit styles** — compact, dot, full (bar + countdown)
- **3 icon sets** — nerd (Nerd Font), unicode, none — plus custom icon sets
- **Fast** — single `jq` call, rest is bash arithmetic (~30ms)
- **Compatible** — macOS bash 3.2+, no dependencies beyond `jq`

## Install

```bash
git clone https://github.com/vkartaviy/statusline.git
cd statusline
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

### Nerd Font (optional)

For `--icons nerd` (default), install a [Nerd Font](https://www.nerdfonts.com/) and set it as your terminal font:

```bash
brew install --cask font-jetbrains-mono-nerd-font
```

Without a Nerd Font, use `--icons unicode` or `--icons none`.

## Usage

```
bash statusline.sh [OPTIONS]
```

| Option | Default | Description |
|--------|---------|-------------|
| `--segments LIST` | `directory,context_bar` | Comma-separated segment names |
| `--theme NAME` | `default` | Theme: `default`, `minimal`, `neon`, `monochrome` |
| `--icons STYLE` | `nerd` | Icon set: `nerd`, `unicode`, `none`, or custom |
| `--bar-width N` | `20` | Bar width in characters |
| `--bar-style STYLE` | `block` | Bar style: `block`, `shade`, `dot`, `ascii` |
| `--separator STR` | ` \| ` | String between segments |
| `--rate-style STYLE` | `compact` | Rate display: `compact`, `dot`, `full` |
| `--no-icons` | — | Alias for `--icons none` |
| `--no-color` | — | Disable all ANSI codes |
| `--config PATH` | `~/.config/claude-statusline/config` | Config file path |
| `--help` | — | Show help |

Config hierarchy: CLI flags > config file > built-in defaults.

## Segments

| Segment | Output | Description |
|---------|--------|-------------|
| `directory` | `Tapelet/src` | Last 2 path components |
| `context_bar` | `■■■■■■□□□□□□□□ 42%` | Context window usage bar |
| `context_pct` | `42%` | Context percentage only |
| `model` | `Opus` | Model display name |
| `cost` | `$1.23` | Session cost |
| `rate_limits` | `5h:23% · 7d:41%` | API rate limits |
| `vim_mode` | `NORMAL` | Vim mode indicator |
| `worktree` | `feature-xyz` | Git worktree name |
| `session_time` | `12m 34s` | Session duration |
| `lines_changed` | `+156 -23` | Lines added/removed |

All segments read only JSON from Claude Code stdin — no shell commands, no filesystem access.
Context bar auto-adapts to both 200K and 1M context windows.

## Themes

| Theme | Description |
|-------|-------------|
| `default` | Green → yellow → red gradient |
| `minimal` | Dim/subtle colors |
| `neon` | Bold vivid 256-color |
| `monochrome` | No ANSI codes |

## Icons

| `--icons` | Requires | Example |
|-----------|----------|---------|
| `nerd` | Nerd Font | ` Tapelet/src` |
| `unicode` | Any font | `› Tapelet/src` |
| `none` | — | `Tapelet/src` |

**Custom icons:** create a file in `icons/` (see `icons/example.sh`) and use `--icons <name>`.

## Rate Limit Styles

| `--rate-style` | Output |
|----------------|--------|
| `compact` | `5h:23% · 7d:41%` |
| `dot` | `●` (colored by worst limit) |
| `full` | `5h ■□□□□□□□ ⟳2h · 7d ■■■□□□□□ ⟳4d` |

Color thresholds: green <50%, yellow 50-80%, red >80%.

## Preview

```bash
bash preview.sh              # Show everything
bash preview.sh --theme neon  # Preview one theme
```

## Examples

**Minimal:**
```json
{
  "statusLine": {
    "type": "command",
    "command": "bash statusline.sh --segments directory,context_bar"
  }
}
```

**Full monitoring:**
```json
{
  "statusLine": {
    "type": "command",
    "command": "bash statusline.sh --segments directory,context_bar,model,cost,rate_limits --rate-style dot"
  }
}
```

**Developer:**
```json
{
  "statusLine": {
    "type": "command",
    "command": "bash statusline.sh --segments directory,context_bar,model,lines_changed,session_time"
  }
}
```

**Plain text:**
```json
{
  "statusLine": {
    "type": "command",
    "command": "bash statusline.sh --icons none --no-color"
  }
}
```

## Config File

`~/.config/claude-statusline/config`:

```
SEGMENTS=directory,context_bar,model
THEME=default
BAR_WIDTH=20
BAR_STYLE=block
SEPARATOR= |
RATE_STYLE=compact
ICONS=nerd
```

## License

MIT
