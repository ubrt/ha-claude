# Claude Home — Home Assistant Addon

Runs [Claude Code](https://claude.ai/code) as a Home Assistant addon with a browser-based terminal, direct access to the HA configuration directory, and full integration with the Home Assistant MCP server.

## Warning

**Use at your own risk.**

- **Always create a full Home Assistant backup before using Claude Home.** Claude has direct write access to your configuration and can make changes that are difficult to reverse.
- **Devices may be switched on or off unexpectedly.** Claude can control all entities in your Home Assistant instance via the MCP server. Misunderstood instructions or errors in automation logic can cause lights, switches, or other devices to activate without warning.
- **The periodic loop runs unattended.** When the loop feature is enabled, Claude executes tasks automatically in the background without user confirmation. Carefully review the configured loop task and monitor its behavior, especially during initial setup.

## Features

- Browser-based terminal via ttyd and xterm.js, accessible through HA Ingress
- Persistent sessions via tmux — closing the panel does not interrupt a running conversation
- Session starts immediately at container startup, independent of whether the web panel is open
- Automatic session resume on restart (continues the last conversation when one exists)
- Pre-configured MCP server integration for direct HA control from Claude
- Home Assistant best-practices skill loaded automatically
- Broad file permissions pre-approved for `/config` — no confirmation prompts during normal operation
- Configurable periodic loop with automatic self-renewal

## Requirements

- Home Assistant OS or Supervised installation
- A Claude.ai Pro account (used for OAuth authentication on first start)
- A running Home Assistant MCP server with an accessible HTTP endpoint

## Installation

1. In Home Assistant, go to **Settings → Add-ons → Add-on Store**
2. Open the overflow menu (top right) and select **Repositories**
3. Add `https://github.com/ubrt/ha-claude` and confirm
4. Find **Claude Home** in the store and install it

## Configuration

| Option | Type | Description |
|--------|------|-------------|
| `mcp_url` | string | Full URL to the Home Assistant MCP server HTTP endpoint, including any authentication token |
| `model` | string | Claude model to use, e.g. `claude-opus-4-6` or `claude-sonnet-4-6` |
| `auto_updates_channel` | string | Update channel for Claude Home: `latest` or `beta` |
| `notes` | string | Additional context included in every session — describe your setup, rooms, or preferences |
| `loop_enabled` | bool | Enable the periodic task loop |
| `loop_interval` | int | How often the loop runs, in minutes |
| `loop_start_delay` | int | Seconds to wait after session start before the loop activates |
| `loop_task` | string | What Claude should do on each loop iteration, described in plain text |

## First Start

1. Start the addon and open it from the sidebar
2. Claude Home will display an authentication URL
3. Open the URL in a browser tab, log in with your Claude.ai account, and authorize the device
4. Authentication credentials are stored in the persistent `/data` volume and survive addon updates and restarts

## Session Persistence

The terminal runs inside a tmux session named `claude`. The session is created immediately when the addon starts — you do not need to have the web panel open. When you open the sidebar panel, ttyd attaches to the running session. Closing the panel leaves the session intact in the background. If the addon is restarted and a previous conversation exists, Claude Home resumes it automatically via `--continue`.

## Periodic Loop

When `loop_enabled` is set to `true`, Claude automatically starts a recurring task loop after `loop_start_delay` seconds. The loop runs every `loop_interval` minutes and executes whatever is configured in `loop_task`. The loop self-renews before the 3-day session limit is reached, so it keeps running indefinitely as long as the addon is active.

**Note:** The loop runs unattended. Monitor its behavior and keep the task description precise to avoid unintended actions.

## MCP Server

The addon writes a `.mcp.json` file to `/config` on every start, pointing Claude Home at the configured MCP server URL. This gives Claude direct access to Home Assistant entities, automations, scripts, and dashboards without leaving the terminal.

The recommended MCP server for Home Assistant is [ha-mcp](https://github.com/homeassistant-ai/ha-mcp), which exposes the Home Assistant API via the Model Context Protocol over HTTP. Follow its installation instructions to obtain the endpoint URL and any required authentication token to enter in the addon configuration.

## Development

The addon is built on the official Home Assistant Debian base image. Claude Code is installed via npm during the image build. The web terminal is provided by [ttyd](https://github.com/tsl0922/ttyd).

To update the addon after making changes to local files, increment `version` in `config.yaml`, copy the files to `/addons/claude_code/` on the HA host, and trigger a reload via **Add-on Store → Check for updates**.
