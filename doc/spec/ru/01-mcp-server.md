# MCP-сервер и HTTP-эндпоинт

[Deutsch](../de/01-mcp-server.md) | [English](../en/01-mcp-server.md) | [Español](../es/01-mcp-server.md) | [Français](../fr/01-mcp-server.md) | [Italiano](../it/01-mcp-server.md) | [日本語](../ja/01-mcp-server.md) | [한국어](../ko/01-mcp-server.md) | [Polski](../pl/01-mcp-server.md) | [Português (Brasil)](../pt-BR/01-mcp-server.md) | [Русский](01-mcp-server.md) | [中文](../zh/01-mcp-server.md)

## Обзор

Redmine MCP предоставляет HTTP-эндпоинт `/mcp`, реализующий протокол MCP (Model Context Protocol) в режиме Streamable HTTP без сохранения сессии между запросами (stateless).

## Цель

Позволить внешним AI-клиентам взаимодействовать с Redmine по стандартному протоколу MCP без отдельного процесса-сервера.

## Затронутые области

- API
- Plugins

## Бизнес-правила

- Эндпоинт доступен по пути `/mcp` относительно корня Redmine.
- Поддерживаются HTTP-методы `GET`, `POST`, `DELETE` в соответствии со спецификацией Streamable HTTP.
- Каждый запрос обрабатывается в контексте текущего аутентифицированного пользователя.
- Для каждого запроса формируется актуальный набор tools, resources и prompts с учётом прав пользователя.
- Сервер объявляет имя `redmine_mcp` и версию, соответствующую версии плагина.
- Protocol Revision MCP — `2025-11-25` (заголовок `MCP-Protocol-Version` и `protocolVersion` в `initialize`).
- Поддерживаются стандартные MCP-методы: `initialize`, `tools/list`, `tools/call`, `resources/list`, `resources/read`, `prompts/list`, `prompts/get` и другие, предусмотренные используемой версией протокола.
- Ответы инструментов возвращают JSON-envelope в `structuredContent` (`ok`, `data` или `error`) и краткое текстовое представление в `content` (JSON-строка для успеха, сообщение ошибки для отказа).
- API-ключ принимается только из заголовка `X-Redmine-API-Key`. Тело JSON-RPC не используется для аутентификации и не разбирается до проверки размера запроса.
- Размер HTTP-тела ограничивается до разбора JSON: при превышении лимита запрос отклоняется, MCP-транспорт тело не читает.

## Граничные случаи

- При выключенном MCP эндпоинт возвращает HTTP 503 и не обрабатывает MCP-запросы.
- В stateless-режиме `GET`-запросы для standalone SSE-потока не поддерживаются (HTTP 405) — это ожидаемое поведение.
- При работе за балансировщиком sticky sessions не требуются.
- Список tools у разных пользователей может отличаться в зависимости от прав.

## Обработка ошибок

- Некорректный JSON-RPC-запрос — ответ с кодом ошибки протокола MCP.
- Внутренняя ошибка при обработке запроса — HTTP 500 с сообщением об ошибке.
- Ошибка выполнения инструмента — ответ MCP с `isError: true` и текстовым описанием.
- In-process REST (`InternalRequest`): 404 → `NOT_FOUND`; конфликт версии → `CONFLICT`; 401/403 без конфликта → `FORBIDDEN`; массив `errors` → `VALIDATION_ERROR`. В envelope нет HTTP-статуса внутреннего запроса и сырого exception message.
- Невалидные аргументы инструмента (нет обязательных полей, неверный тип, лишние свойства при `additionalProperties: false`, выход за min/max) — ошибка выполнения с envelope `VALIDATION_ERROR` в `structuredContent`. Текст в `content` совпадает с `error.message` и не содержит сырых сообщений JSON Schema.

## Тестовые сценарии

1. `POST /mcp` с методом `initialize` возвращает capabilities, `serverInfo` и `protocolVersion` `2025-11-25`.
2. `POST /mcp` с методом `tools/list` возвращает список инструментов текущего пользователя.
3. `POST /mcp` с методом `tools/call` и валидным именем инструмента возвращает результат с `structuredContent`.
4. Запрос к `/mcp` при выключенном MCP возвращает HTTP 503.
5. Вызов несуществующего инструмента возвращает ошибку «Tool not found».
6. `tools/call` без прав на инструмент возвращает ошибку выполнения с кодом отказа в доступе; вызов учитывается в rate limit и structured audit.
7. HTTP-тело больше лимита отклоняется до разбора JSON.
8. Write-tool при включённом read-only возвращает ошибку через тот же HTTP/`tools/call` путь.
9. `resources/read` с URI недоступного проекта не возвращает содержимое ресурса.
10. `prompts/get` с аргументом недоступного проекта отказывает в доступе.
11. `tools/call` с пустыми args, лишним полем или неверным типом аргумента возвращает `isError: true` и `structuredContent.error.code` `VALIDATION_ERROR`.
