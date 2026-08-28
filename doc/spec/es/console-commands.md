# Comandos de instalación, verificación y mantenimiento

[Deutsch](../de/console-commands.md) | [English](../en/console-commands.md) | [Español](console-commands.md) | [Français](../fr/console-commands.md) | [Italiano](../it/console-commands.md) | [日本語](../ja/console-commands.md) | [한국어](../ko/console-commands.md) | [Polski](../pl/console-commands.md) | [Português (Brasil)](../pt-BR/console-commands.md) | [Русский](../ru/console-commands.md) | [中文](../zh/console-commands.md)

## Instalación

```bash
bundle install
```

Tras instalar las dependencias, reinicie Redmine.

## Verificación del endpoint

Comprobación de inicialización de MCP:

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

Resultado esperado: HTTP 200, `serverInfo.name` en la respuesta es igual a `redmine_mcp`.

## Comprobación de la lista de herramientas

```bash
curl -s -X POST 'http://localhost:3000/mcp' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H 'MCP-Protocol-Version: 2025-11-25' \
  -H 'X-Redmine-API-Key: YOUR_API_KEY' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
```

## Comprobación de invocación de herramienta

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

## Visualización de registros

Los mensajes del plugin se escriben en el registro estándar de Rails con el prefijo `[redmine_mcp]`:

```bash
tail -f log/production.log | grep redmine_mcp
```

## Mantenimiento

- Tras cambiar la configuración del plugin o instalar una nueva extensión — reinicie Redmine.
- Tras añadir una nueva herramienta MCP — reconecte el cliente MCP (reinicie Cursor o elimine/añada el servidor en la configuración MCP).
