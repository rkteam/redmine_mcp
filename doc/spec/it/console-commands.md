# Comandi di installazione, verifica e manutenzione

[Deutsch](../de/console-commands.md) | [English](../en/console-commands.md) | [Español](../es/console-commands.md) | [Français](../fr/console-commands.md) | [Italiano](console-commands.md) | [日本語](../ja/console-commands.md) | [한국어](../ko/console-commands.md) | [Polski](../pl/console-commands.md) | [Português (Brasil)](../pt-BR/console-commands.md) | [Русский](../ru/console-commands.md) | [中文](../zh/console-commands.md)

## Installazione

```bash
bundle install
```

Dopo l'installazione delle dipendenze, riavviare Redmine.

## Verifica dell'endpoint

Controllo di inizializzazione MCP:

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

Risultato atteso: HTTP 200, `serverInfo.name` nella risposta è uguale a `redmine_mcp`.

## Controllo dell'elenco degli strumenti

```bash
curl -s -X POST 'http://localhost:3000/mcp' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H 'MCP-Protocol-Version: 2025-11-25' \
  -H 'X-Redmine-API-Key: YOUR_API_KEY' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
```

## Controllo della chiamata di uno strumento

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

## Visualizzazione dei log

I messaggi del plugin vengono scritti nel log Rails standard con il prefisso `[redmine_mcp]`:

```bash
tail -f log/production.log | grep redmine_mcp
```

## Manutenzione

- Dopo la modifica delle impostazioni del plugin o l'installazione di una nuova estensione — riavviare Redmine.
- Dopo l'aggiunta di un nuovo strumento MCP — riconnettere il client MCP (riavviare Cursor o rimuovere/aggiungere il server nelle impostazioni MCP).
