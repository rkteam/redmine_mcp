# Serwer MCP i punkt końcowy HTTP

[Deutsch](../de/01-mcp-server.md) | [English](../en/01-mcp-server.md) | [Español](../es/01-mcp-server.md) | [Français](../fr/01-mcp-server.md) | [Italiano](../it/01-mcp-server.md) | [日本語](../ja/01-mcp-server.md) | [한국어](../ko/01-mcp-server.md) | [Polski](01-mcp-server.md) | [Português (Brasil)](../pt-BR/01-mcp-server.md) | [Русский](../ru/01-mcp-server.md) | [中文](../zh/01-mcp-server.md)

## Przegląd

Redmine MCP udostępnia punkt końcowy HTTP `/mcp` implementujący MCP (Model Context Protocol) w trybie Streamable HTTP bez utrzymywania sesji między żądaniami (stateless).

## Cel

Umożliwić zewnętrznym klientom AI interakcję z Redmine przy użyciu standardowego protokołu MCP bez osobnego procesu serwera.

## Obszary objęte

- API
- Wtyczki

## Reguły biznesowe

- Punkt końcowy jest dostępny pod `/mcp` względem katalogu głównego Redmine.
- Obsługiwane są metody HTTP `GET`, `POST` i `DELETE` zgodnie ze specyfikacją Streamable HTTP.
- Każde żądanie jest obsługiwane w kontekście bieżącego uwierzytelnionego użytkownika.
- Dla każdego żądania budowany jest aktualny zestaw narzędzi, zasobów i promptów zgodnie z uprawnieniami użytkownika.
- Serwer reklamuje nazwę `redmine_mcp` i wersję zgodną z wersją wtyczki.
- Rewizja protokołu MCP to `2025-11-25` (nagłówek `MCP-Protocol-Version` i `protocolVersion` w `initialize`).
- Obsługiwane są standardowe metody MCP: `initialize`, `tools/list`, `tools/call`, `resources/list`, `resources/read`, `prompts/list`, `prompts/get` oraz inne zapewniane przez obsługiwaną wersję protokołu.
- Odpowiedzi narzędzi zwracają kopertę JSON w `structuredContent` (`ok`, `data` lub `error`) oraz krótką reprezentację tekstową w `content` (ciąg JSON przy sukcesie, komunikat błędu przy niepowodzeniu).
- Klucz API jest akceptowany wyłącznie z nagłówka `X-Redmine-API-Key`. Treść JSON-RPC nie służy do uwierzytelniania i nie jest parsowana przed sprawdzeniem rozmiaru żądania.
- Rozmiar treści HTTP jest ograniczony przed parsowaniem JSON: po przekroczeniu limitu żądanie jest odrzucane, a transport MCP nie odczytuje treści.

## Przypadki brzegowe

- Gdy MCP jest wyłączone, punkt końcowy zwraca HTTP 503 i nie przetwarza żądań MCP.
- W trybie bezstanowym żądania `GET` dla samodzielnego strumienia SSE nie są obsługiwane (HTTP 405) — to oczekiwane zachowanie.
- Przy pracy za load balancerem sticky sessions nie są wymagane.
- Lista narzędzi może różnić się między użytkownikami w zależności od uprawnień.

## Obsługa błędów

- Nieprawidłowe żądanie JSON-RPC — odpowiedź błędu protokołu MCP.
- Wewnętrzny błąd przetwarzania żądania — HTTP 500 z komunikatem błędu.
- Błąd wykonania narzędzia — odpowiedź MCP z `isError: true` i opisem tekstowym.
- REST w procesie (`InternalRequest`): 404 → `NOT_FOUND`; konflikt wersji → `CONFLICT`; 401/403 bez konfliktu → `FORBIDDEN`; tablica `errors` → `VALIDATION_ERROR`. Koperta nie zawiera wewnętrznego statusu HTTP żądania ani surowego komunikatu wyjątku.
- Nieprawidłowe argumenty narzędzia (brak wymaganych pól, zły typ, dodatkowe właściwości przy `additionalProperties: false`, poza zakresem min/max) — błąd wykonania z `VALIDATION_ERROR` w `structuredContent`. Tekst w `content` odpowiada `error.message` i nie zawiera surowych komunikatów JSON Schema.

## Scenariusze testowe

1. `POST /mcp` z metodą `initialize` zwraca capabilities, `serverInfo` i `protocolVersion` `2025-11-25`.
2. `POST /mcp` z metodą `tools/list` zwraca listę narzędzi bieżącego użytkownika.
3. `POST /mcp` z metodą `tools/call` i prawidłową nazwą narzędzia zwraca wynik z `structuredContent`.
4. Żądanie do `/mcp` przy wyłączonym MCP zwraca HTTP 503.
5. Wywołanie nieistniejącego narzędzia zwraca błąd „Tool not found”.
6. `tools/call` bez uprawnienia do narzędzia zwraca błąd wykonania z kodem odmowy dostępu; wywołanie jest liczone w rate limit i strukturalnym audycie.
7. Treść HTTP większa niż limit jest odrzucana przed parsowaniem JSON.
8. Narzędzie zapisu przy włączonym trybie tylko do odczytu zwraca błąd tą samą ścieżką HTTP/`tools/call`.
9. `resources/read` z URI niedostępnego projektu nie zwraca treści zasobu.
10. `prompts/get` z argumentem niedostępnego projektu odmawia dostępu.
11. `tools/call` z pustymi argumentami, dodatkowym polem lub złym typem argumentu zwraca `isError: true` i `structuredContent.error.code` `VALIDATION_ERROR`.
