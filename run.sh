#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

export HOME=/data
mkdir -p /data/.claude

# Read addon config
MCP_URL=$(bashio::config 'mcp_url')
MODEL=$(bashio::config 'model')
AUTO_UPDATES=$(bashio::config 'auto_updates_channel')

# Build settings.json dynamically from addon config
cat > /data/.claude/settings.json << EOF
{
  "enabledPlugins": {
    "home-assistant-skills@home-assistant-skills": true
  },
  "extraKnownMarketplaces": {
    "home-assistant-skills": {
      "source": {
        "source": "github",
        "repo": "homeassistant-ai/skills"
      }
    }
  },
  "autoUpdatesChannel": "${AUTO_UPDATES}",
  "permissions": {
    "allow": [
      "mcp__ha__*",
      "Read(**)",
      "Edit(**)",
      "Write(**)",
      "Bash(*)"
    ]
  }
}
EOF

# Write MCP server config
cat > /config/.mcp.json << EOF
{
  "mcpServers": {
    "ha": {
      "type": "http",
      "url": "${MCP_URL}"
    }
  }
}
EOF

# Build claude CLI flags
CLAUDE_FLAGS=""
if find /data/.claude/projects -name "*.jsonl" 2>/dev/null | grep -q .; then
  CLAUDE_FLAGS="--continue"
fi
if bashio::config.has_value 'model'; then
  CLAUDE_FLAGS="${CLAUDE_FLAGS} --model ${MODEL}"
fi

bashio::log.info "Starting Claude Code (model: ${MODEL})"

exec ttyd \
  --port 7681 \
  --writable \
  tmux new-session -A -s claude bash -c "cd /config && claude ${CLAUDE_FLAGS}; exec bash"
