# MCP-Server und HTTP-Endpunkt

[Deutsch](01-mcp-server.md) | [English](../en/01-mcp-server.md) | [Español](../es/01-mcp-server.md) | [Français](../fr/01-mcp-server.md) | [Italiano](../it/01-mcp-server.md) | [日本語](../ja/01-mcp-server.md) | [한국어](../ko/01-mcp-server.md) | [Polski](../pl/01-mcp-server.md) | [Português (Brasil)](../pt-BR/01-mcp-server.md) | [Русский](../ru/01-mcp-server.md) | [中文](../zh/01-mcp-server.md)

## Überblick

Redmine MCP stellt einen HTTP-Endpunkt `/mcp` bereit, der MCP (Model Context Protocol) im Streamable-HTTP-Modus ohne Session-Persistenz zwischen Anfragen (stateless) implementiert.

## Ziel

Externen AI-Clients die Interaktion mit Redmine über das standardisierte MCP-Protokoll ohne separaten Serverprozess ermöglichen.

## Betroffene Bereiche

- API
- Plugins

## Geschäftsregeln

- Der Endpunkt ist relativ zur Redmine-Root unter `/mcp` erreichbar.
- HTTP-Methoden `GET`, `POST` und `DELETE` werden gemäß der Streamable-HTTP-Spezifikation unterstützt.
- Jede Anfrage wird im Kontext des aktuell authentifizierten Benutzers verarbeitet.
- Pro Anfrage wird ein aktueller Satz von Tools, Resources und Prompts gemäß den Berechtigungen des Benutzers aufgebaut.
- Der Server gibt den Namen `redmine_mcp` und eine Version an, die der Plugin-Version entspricht.
- MCP Protocol Revision ist `2025-11-25` (Header `MCP-Protocol-Version` und `protocolVersion` in `initialize`).
- Standard-MCP-Methoden werden unterstützt: `initialize`, `tools/list`, `tools/call`, `resources/list`, `resources/read`, `prompts/list`, `prompts/get` und weitere der unterstützten Protokollversion.
- Tool-Antworten liefern eine JSON-Hülle in `structuredContent` (`ok`, `data` oder `error`) und eine kurze Textdarstellung in `content` (JSON-String bei Erfolg, Fehlermeldung bei Misserfolg).
- Der API-Schlüssel wird nur aus dem Header `X-Redmine-API-Key` akzeptiert. Der JSON-RPC-Body wird nicht für die Authentifizierung verwendet und vor der Größenprüfung der Anfrage nicht geparst.
- Die HTTP-Body-Größe ist vor dem JSON-Parsing begrenzt: wird das Limit überschritten, wird die Anfrage abgelehnt und der MCP-Transport liest den Body nicht.

## Randfälle

- Ist MCP deaktiviert, liefert der Endpunkt HTTP 503 und verarbeitet keine MCP-Anfragen.
- Im stateless Modus werden `GET`-Anfragen für einen eigenständigen SSE-Stream nicht unterstützt (HTTP 405) — erwartetes Verhalten.
- Hinter einem Load Balancer sind sticky sessions nicht erforderlich.
- Die Tool-Liste kann je nach Berechtigungen zwischen Benutzern unterschiedlich sein.

## Fehlerbehandlung

- Ungültige JSON-RPC-Anfrage — MCP-Protokoll-Fehlerantwort.
- Interner Fehler bei der Anfrageverarbeitung — HTTP 500 mit Fehlermeldung.
- Fehler bei der Tool-Ausführung — MCP-Antwort mit `isError: true` und Textbeschreibung.
- In-Process-REST (`InternalRequest`): 404 → `NOT_FOUND`; Versionskonflikt → `CONFLICT`; 401/403 ohne Konflikt → `FORBIDDEN`; `errors`-Array → `VALIDATION_ERROR`. Die Hülle enthält weder den internen HTTP-Status der Anfrage noch eine rohe Exception-Meldung.
- Ungültige Tool-Argumente (fehlende Pflichtfelder, falscher Typ, zusätzliche Properties bei `additionalProperties: false`, außerhalb min/max) — Ausführungsfehler mit `VALIDATION_ERROR` in `structuredContent`. Text in `content` entspricht `error.message` und enthält keine rohen JSON-Schema-Meldungen.

## Testszenarien

1. `POST /mcp` mit Methode `initialize` liefert Capabilities, `serverInfo` und `protocolVersion` `2025-11-25`.
2. `POST /mcp` mit Methode `tools/list` liefert die Tool-Liste des aktuellen Benutzers.
3. `POST /mcp` mit Methode `tools/call` und gültigem Tool-Namen liefert ein Ergebnis mit `structuredContent`.
4. Eine Anfrage an `/mcp` bei deaktiviertem MCP liefert HTTP 503.
5. Aufruf eines nicht existierenden Tools liefert einen Fehler „Tool not found“.
6. `tools/call` ohne Berechtigung für das Tool liefert einen Ausführungsfehler mit Zugriff-verweigert-Code; der Aufruf wird im Rate Limit und strukturierten Audit gezählt.
7. Ein HTTP-Body größer als das Limit wird vor dem JSON-Parsing abgelehnt.
8. Ein Schreib-Tool bei aktiviertem Read-only-Modus liefert einen Fehler über denselben HTTP/`tools/call`-Pfad.
9. `resources/read` mit URI für ein nicht zugängliches Projekt liefert keinen Resource-Inhalt.
10. `prompts/get` mit nicht zugänglichem Projekt-Argument verweigert den Zugriff.
11. `tools/call` mit leeren Args, zusätzlichem Feld oder falschem Argumenttyp liefert `isError: true` und `structuredContent.error.code` `VALIDATION_ERROR`.
