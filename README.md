# Claude Code — Home Assistant Addon

Runs [Claude Code](https://claude.ai/code) as a Home Assistant addon with a browser-based terminal, direct access to the HA configuration directory, and full integration with the Home Assistant MCP server.

## Features

- Browser-based terminal via ttyd and xterm.js, accessible through HA Ingress
- Persistent sessions via tmux — closing the panel does not interrupt a running conversation
- Automatic session resume on restart (continues the last conversation when one exists)
- Pre-configured MCP server integration for direct HA control from Claude
- Home Assistant best-practices skill loaded automatically
- Broad file permissions pre-approved for `/config` — no confirmation prompts during normal operation

## Requirements

- Home Assistant OS or Supervised installation
- A Claude.ai Pro account (used for OAuth authentication on first start)
- A running Home Assistant MCP server with an accessible HTTP endpoint

## Installation

1. In Home Assistant, go to **Settings → Add-ons → Add-on Store**
2. Open the overflow menu (top right) and select **Repositories**
3. Add `https://github.com/ubrt/ha-claude` and confirm
4. Find **Claude Code** in the store and install it

## Configuration

| Option | Type | Description |
|--------|------|-------------|
| `mcp_url` | string | Full URL to the Home Assistant MCP server HTTP endpoint, including any authentication token |
| `model` | string | Claude model to use, e.g. `claude-opus-4-6` or `claude-sonnet-4-6` |
| `auto_updates_channel` | string | Update channel for Claude Code: `latest` or `beta` |

## First Start

1. Start the addon and open it from the sidebar
2. Claude Code will display an authentication URL
3. Open the URL in a browser tab, log in with your Claude.ai account, and authorize the device
4. Authentication credentials are stored in the persistent `/data` volume and survive addon updates and restarts

## Session Persistence

The terminal runs inside a tmux session named `claude`. When you close the sidebar panel, the session continues running in the background. Re-opening the panel reattaches to the existing session. If the addon is restarted and a previous conversation exists, Claude Code resumes it automatically via `--continue`.

## MCP Server

The addon writes a `.mcp.json` file to `/config` on every start, pointing Claude Code at the configured MCP server URL. This gives Claude direct access to Home Assistant entities, automations, scripts, and dashboards without leaving the terminal.

The recommended MCP server for Home Assistant is [ha-mcp](https://github.com/homeassistant-ai/ha-mcp), which exposes the Home Assistant API via the Model Context Protocol over HTTP. Follow its installation instructions to obtain the endpoint URL and any required authentication token to enter in the addon configuration.

## Development

The addon is built on the official Home Assistant Debian base image. Claude Code is installed via npm during the image build. The web terminal is provided by [ttyd](https://github.com/tsl0922/ttyd).

To update the addon after making changes to local files, increment `version` in `config.yaml`, copy the files to `/addons/claude_code/` on the HA host, and trigger a reload via **Add-on Store → Check for updates**.
