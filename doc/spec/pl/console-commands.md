# Polecenia instalacji, weryfikacji i konserwacji

[Deutsch](../de/console-commands.md) | [English](../en/console-commands.md) | [Español](../es/console-commands.md) | [Français](../fr/console-commands.md) | [Italiano](../it/console-commands.md) | [日本語](../ja/console-commands.md) | [한국어](../ko/console-commands.md) | [Polski](console-commands.md) | [Português (Brasil)](../pt-BR/console-commands.md) | [Русский](../ru/console-commands.md) | [中文](../zh/console-commands.md)

## Instalacja

```bash
bundle install
```

Po zainstalowaniu zależności zrestartuj Redmine.

## Weryfikacja punktu końcowego

Sprawdzenie inicjalizacji MCP:

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

Oczekiwany wynik: HTTP 200, `serverInfo.name` w odpowiedzi równa się `redmine_mcp`.

## Sprawdzenie listy narzędzi

```bash
curl -s -X POST 'http://localhost:3000/mcp' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H 'MCP-Protocol-Version: 2025-11-25' \
  -H 'X-Redmine-API-Key: YOUR_API_KEY' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
```

## Sprawdzenie wywołania narzędzia

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

## Przeglądanie logów

Komunikaty wtyczki są zapisywane do standardowego logu Rails z prefiksem `[redmine_mcp]`:

```bash
tail -f log/production.log | grep redmine_mcp
```

## Konserwacja

- Po zmianie ustawień wtyczki lub zainstalowaniu nowego rozszerzenia — zrestartuj Redmine.
- Po dodaniu nowego narzędzia MCP — ponownie połącz klienta MCP (zrestartuj Cursor lub usuń/dodaj serwer w ustawieniach MCP).
