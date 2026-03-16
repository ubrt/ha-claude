#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

export HOME=/data
mkdir -p /data/.claude

# Read addon config
MCP_URL=$(bashio::config 'mcp_url')
MODEL=$(bashio::config 'model')
AUTO_UPDATES=$(bashio::config 'auto_updates_channel')
NOTES=$(bashio::config 'notes')
LOOP_ENABLED=$(bashio::config 'loop_enabled')
LOOP_INTERVAL=$(bashio::config 'loop_interval')
LOOP_START_DELAY=$(bashio::config 'loop_start_delay')
LOOP_TASK=$(bashio::config 'loop_task')

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
      "Bash(*)",
      "WebSearch(*)",
      "WebFetch(*)"
    ],
    "deny": [
      "Read(/config/secrets.yaml)"
    ]
  }
}
EOF

# Write CLAUDE.md into /config (working directory)
cat > /config/CLAUDE.md << EOF
# Home Assistant — Claude Context

## Environment
- Working directory: /config (Home Assistant configuration)
- MCP server connected: ${MCP_URL}
- All HA entities, automations, scripts and dashboards are accessible via MCP tools

## Key conventions
- Use \`entity_id\` in triggers and actions, never \`device_id\`
- Dashboard edits: prefer \`python_transform\` over full config replacement
- Blueprints are stored in \`/config/blueprints/automation/homeassistant/\`

## Backups
- Before performing critical refactoring (removing or restructuring automations, scripts, dashboards, or configuration files), check when the last backup was created. Only ask the user whether a backup should be created if no backup exists from the recent past.

## Learning
- When an MCP tool call fails or behaves unexpectedly, identify the correct usage and save it to memory before retrying. This prevents repeating the same mistake in future sessions.

## Restrictions
- Never read or output the contents of /config/secrets.yaml

## Periodic loop
- Loop enabled: ${LOOP_ENABLED}
- Loop interval: ${LOOP_INTERVAL} minutes
- Loop task: ${LOOP_TASK}
$(if [ "${LOOP_ENABLED}" = "true" ]; then echo "- On session start, run /ha-loop-start to activate the loop."; fi)

## Notes
${NOTES}
EOF

# Write custom HA commands
# tmux config: enable mouse scrolling
mkdir -p /data
cat > /data/.tmux.conf << 'EOF'
set -g mouse on
set -g history-limit 10000
EOF
export TMUX_CONFIG=/data/.tmux.conf

mkdir -p /data/.claude/commands

cat > /data/.claude/commands/ha-backup.md << 'EOF'
Check when the last Home Assistant backup was created using the MCP tools. Display the result clearly. If no backup exists from the last 24 hours, ask the user whether a new backup should be created and create it if confirmed.
EOF

cat > /data/.claude/commands/ha-check.md << 'EOF'
Validate the current Home Assistant configuration using the MCP check_config tool. Display all errors and warnings clearly. If the configuration is valid, confirm this to the user.
EOF

cat > /data/.claude/commands/ha-restart.md << 'EOF'
Ask the user to confirm before proceeding. If confirmed, restart Home Assistant using the MCP tools and inform the user that the restart has been initiated.
EOF

cat > /data/.claude/commands/ha-log.md << 'EOF'
Fetch the most recent Home Assistant logbook entries using the MCP tools and display them in a clean, readable format. If $ARGUMENTS is provided, use it as a filter (e.g. entity name or keyword).
EOF

cat > /data/.claude/commands/ha-discover.md << 'EOF'
Perform a full scan of the Home Assistant environment using MCP tools. Collect the following:
- All areas and floors
- All devices grouped by area
- All entities grouped by domain and area
- All automations (name, state, last triggered)
- All scripts
- All active helpers (input_boolean, input_number, input_select, etc.)
- All installed dashboards

Summarize the findings and save a structured overview to memory so future interactions can reference the environment without needing to re-scan. Inform the user when the discovery is complete and the memory has been saved.
EOF

cat > /data/.claude/commands/ha-loop-start.md << EOF
Start the periodic home loop. Steps:
1. Save the current timestamp (ISO format) to /data/.claude/loop_started_at
2. Use CronCreate to schedule /ha-loop-run every ${LOOP_INTERVAL} minutes
3. Confirm to the user that the loop is active with the configured interval

If a loop named "ha-loop" is already running (check via CronList), cancel it first with CronDelete, then start a fresh one.
EOF

cat > /data/.claude/commands/ha-loop-run.md << EOF
This command runs on every loop iteration. Execute the following steps:

1. Check /data/.claude/loop_started_at. If the timestamp is older than 23 hours, renew the loop:
   - Use CronList to find the current loop, CronDelete to cancel it
   - Write the current timestamp to /data/.claude/loop_started_at
   - Use CronCreate to schedule /ha-loop-run every ${LOOP_INTERVAL} minutes

2. Run the configured periodic task:
${LOOP_TASK}

Keep the response concise. Only surface information that requires user attention.
EOF

cat > /data/.claude/commands/ha-optimize.md << 'EOF'
Analyse the current Home Assistant setup for optimization opportunities. Work through the following systematically:

1. Load all automations via MCP and review each one for: redundant triggers, missing conditions, wrong automation mode, use of device_id instead of entity_id, and template logic that could be replaced by native HA constructs.
2. Load all scripts and check for duplication, unused scripts, and logic that could be simplified.
3. Read all blueprint files from /config/blueprints/ and assess whether they follow best practices.
4. Check all helpers (input_boolean, input_number, etc.) for any that appear unused across automations and scripts.

For each finding, provide a concrete suggestion with a brief explanation of why it is an improvement. Group findings by category (automations, scripts, blueprints, helpers). Do not make any changes — present the findings first and let the user decide what to act on.
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

# Start tmux session immediately (independent of web shell connections)
tmux -f /data/.tmux.conf new-session -d -s claude bash -c "cd /config && exec claude ${CLAUDE_FLAGS}; exec bash"

# Schedule loop start in background if enabled
if [ "${LOOP_ENABLED}" = "true" ]; then
  (sleep "${LOOP_START_DELAY}" && tmux send-keys -t claude '/ha-loop-start' Enter) &
fi

# ttyd attaches to the existing session — works with or without active browser connection
exec ttyd \
  --port 7681 \
  --writable \
  tmux -f /data/.tmux.conf attach-session -t claude
