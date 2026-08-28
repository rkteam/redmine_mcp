# Installation, verification, and maintenance commands

[Deutsch](../de/console-commands.md) | [English](console-commands.md) | [Español](../es/console-commands.md) | [Français](../fr/console-commands.md) | [Italiano](../it/console-commands.md) | [日本語](../ja/console-commands.md) | [한국어](../ko/console-commands.md) | [Polski](../pl/console-commands.md) | [Português (Brasil)](../pt-BR/console-commands.md) | [Русский](../ru/console-commands.md) | [中文](../zh/console-commands.md)

## Installation

```bash
bundle install
```

After installing dependencies, restart Redmine.

## Endpoint verification

MCP initialization check:

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

Expected result: HTTP 200, `serverInfo.name` in the response equals `redmine_mcp`.

## Tool list check

```bash
curl -s -X POST 'http://localhost:3000/mcp' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H 'MCP-Protocol-Version: 2025-11-25' \
  -H 'X-Redmine-API-Key: YOUR_API_KEY' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
```

## Tool call check

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

## Viewing logs

Plugin messages are written to the standard Rails log with the `[redmine_mcp]` prefix:

```bash
tail -f log/production.log | grep redmine_mcp
```

## Maintenance

- After changing plugin settings or installing a new extension — restart Redmine.
- After adding a new MCP tool — reconnect the MCP client (restart Cursor or remove/add the server in MCP settings).
