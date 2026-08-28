# Installations-, Prüf- und Wartungsbefehle

[Deutsch](console-commands.md) | [English](../en/console-commands.md) | [Español](../es/console-commands.md) | [Français](../fr/console-commands.md) | [Italiano](../it/console-commands.md) | [日本語](../ja/console-commands.md) | [한국어](../ko/console-commands.md) | [Polski](../pl/console-commands.md) | [Português (Brasil)](../pt-BR/console-commands.md) | [Русский](../ru/console-commands.md) | [中文](../zh/console-commands.md)

## Installation

```bash
bundle install
```

Nach der Installation der Abhängigkeiten Redmine neu starten.

## Endpunkt-Prüfung

MCP-Initialisierungsprüfung:

```bash
curl -s -X POST 'http://localhost:3000/mcp' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H 'MCP-Protocol-Version: 2025-11-25' \
  -H 'X-Redmine-API-Key: YOUR_API_KEY' \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2025-11-25",
      "capabilities": {},
      "clientInfo": { "name": "curl", "version": "1.0" }
    }
  }'
```

Erwartetes Ergebnis: HTTP 200, `serverInfo.name` in der Antwort entspricht `redmine_mcp`.

## Tool-Listen-Prüfung

```bash
curl -s -X POST 'http://localhost:3000/mcp' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H 'MCP-Protocol-Version: 2025-11-25' \
  -H 'X-Redmine-API-Key: YOUR_API_KEY' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
```

## Tool-Aufruf-Prüfung

```bash
curl -s -X POST 'http://localhost:3000/mcp' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H 'MCP-Protocol-Version: 2025-11-25' \
  -H 'X-Redmine-API-Key: YOUR_API_KEY' \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "redmine_list_projects",
      "arguments": { "limit": 5 }
    }
  }'
```

## Logs anzeigen

Plugin-Meldungen werden mit dem Präfix `[redmine_mcp]` ins standardmäßige Rails-Log geschrieben:

```bash
tail -f log/production.log | grep redmine_mcp
```

## Wartung

- Nach Änderung der Plugin-Einstellungen oder Installation einer neuen Erweiterung — Redmine neu starten.
- Nach Hinzufügen eines neuen MCP-Tools — MCP-Client neu verbinden (Cursor neu starten oder Server in MCP-Einstellungen entfernen/hinzufügen).
