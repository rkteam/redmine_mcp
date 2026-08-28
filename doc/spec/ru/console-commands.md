# Команды установки, проверки и обслуживания

[Deutsch](../de/console-commands.md) | [English](../en/console-commands.md) | [Español](../es/console-commands.md) | [Français](../fr/console-commands.md) | [Italiano](../it/console-commands.md) | [日本語](../ja/console-commands.md) | [한국어](../ko/console-commands.md) | [Polski](../pl/console-commands.md) | [Português (Brasil)](../pt-BR/console-commands.md) | [Русский](console-commands.md) | [中文](../zh/console-commands.md)

## Установка

```bash
bundle install
```

После установки зависимостей необходимо перезапустить Redmine.

## Проверка эндпоинта

Проверка инициализации MCP:

```bash
curl -s -X POST 'http://localhost:3000/mcp' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H 'MCP-Protocol-Version: 2025-11-25' \
  -H 'X-Redmine-API-Key: ВАШ_API_КЛЮЧ' \
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

Ожидаемый результат: HTTP 200, в ответе `serverInfo.name` равен `redmine_mcp`.

## Проверка списка инструментов

```bash
curl -s -X POST 'http://localhost:3000/mcp' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H 'MCP-Protocol-Version: 2025-11-25' \
  -H 'X-Redmine-API-Key: ВАШ_API_КЛЮЧ' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
```

## Проверка вызова инструмента

```bash
curl -s -X POST 'http://localhost:3000/mcp' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H 'MCP-Protocol-Version: 2025-11-25' \
  -H 'X-Redmine-API-Key: ВАШ_API_КЛЮЧ' \
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

## Просмотр логов

Сообщения плагина пишутся в стандартный лог Rails с префиксом `[redmine_mcp]`:

```bash
tail -f log/production.log | grep redmine_mcp
```

## Обслуживание

- После изменения настроек плагина или установки нового расширения — перезапуск Redmine.
- После добавления нового MCP-инструмента — переподключение MCP-клиента (перезапуск Cursor или удаление/добавление сервера в настройках MCP).
