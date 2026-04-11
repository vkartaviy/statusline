#!/usr/bin/env bash
# install.sh — symlink to ~/.local/bin/ + copy default config

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/.local/bin"
CONFIG_DIR="${HOME}/.config/claude-statusline"

echo "claude-statusline installer"
echo "─────────────────────────────"

# Create bin directory
if [ ! -d "$BIN_DIR" ]; then
  echo "Creating ${BIN_DIR}..."
  mkdir -p "$BIN_DIR"
fi

# Symlink
LINK="${BIN_DIR}/claude-statusline"
if [ -L "$LINK" ] || [ -e "$LINK" ]; then
  echo "Updating symlink: ${LINK}"
  rm "$LINK"
else
  echo "Creating symlink: ${LINK}"
fi
ln -s "${SCRIPT_DIR}/statusline.sh" "$LINK"

# Config
if [ ! -d "$CONFIG_DIR" ]; then
  echo "Creating config directory: ${CONFIG_DIR}"
  mkdir -p "$CONFIG_DIR"
fi

CONFIG_FILE="${CONFIG_DIR}/config"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Writing default config: ${CONFIG_FILE}"
  cat > "$CONFIG_FILE" << 'EOF'
# claude-statusline config
# See: claude-statusline --help

SEGMENTS=directory,context_bar
THEME=default
BAR_WIDTH=30
BAR_STYLE=block
SEPARATOR= |
RATE_STYLE=compact
ICONS=1
EOF
else
  echo "Config exists, skipping: ${CONFIG_FILE}"
fi

echo ""
echo "Done! Add to your Claude Code settings (~/.claude/settings.json):"
echo ""
echo '  "statusLine": {'
echo '    "type": "command",'
echo "    \"command\": \"bash ${SCRIPT_DIR}/statusline.sh --segments directory,context_bar,model,cost\""
echo '  }'
echo ""

# Check if ~/.local/bin is in PATH
case ":${PATH}:" in
  *":${BIN_DIR}:"*) ;;
  *)
    echo "Note: ${BIN_DIR} is not in your PATH."
    echo "Add to your shell profile: export PATH=\"\${HOME}/.local/bin:\${PATH}\""
    ;;
esac
