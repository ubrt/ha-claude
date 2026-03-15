# Claude Code HA Addon

Claude Code CLI direkt in Home Assistant, mit vollem Zugriff auf `/config` und dem HA MCP Server.

## Installation

1. In HA: **Einstellungen → Add-ons → Add-on Store → ⋮ → Eigenes Repository hinzufügen**
2. Pfad zum Addon-Ordner angeben (oder GitHub-Repo)
3. Addon installieren

## Konfiguration

| Option | Beschreibung |
|--------|-------------|
| `mcp_url` | URL zum HA MCP Server (SSE), z.B. `http://homeassistant:8123/mcp_server/sse` |
| `mcp_token` | Long-Lived Access Token (falls die MCP URL Auth erfordert) |

Den Token erstellt du unter: **Profil → Sicherheit → Long-Lived Access Tokens**

## Erster Start / Login

Beim ersten Start muss Claude Code einmalig authentifiziert werden:

1. Addon starten → Terminal öffnet sich im HA Sidebar
2. `claude` wird automatisch gestartet
3. Eine URL erscheint → im Browser öffnen → mit Claude.ai Pro Account einloggen
4. Fertig — Credentials werden in `/data/.claude/` gespeichert und bleiben dauerhaft erhalten

## Enthaltene Plugins

- **home-assistant-skills** — Best Practices für HA Automationen, Helfer, Scripts und Dashboards

## Overlay (optional) — Browser Mod

Für ein echtes Overlay auf jeder Dashboard-Seite:

1. [Browser Mod](https://github.com/thomasloven/hass-browser_mod) via HACS installieren
2. Folgenden Button zu deinem Dashboard hinzufügen:

```yaml
type: button
name: Claude Code
icon: mdi:robot
tap_action:
  action: fire-dom-event
  browser_mod:
    service: browser_mod.popup
    data:
      title: Claude Code
      size: wide
      content:
        type: iframe
        url: /api/hassio_ingress/claude_code/
        aspect_ratio: "75%"
```

Damit öffnet sich Claude Code als Popup-Overlay auf der aktuellen Seite.
